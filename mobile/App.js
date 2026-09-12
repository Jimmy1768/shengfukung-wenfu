import { StatusBar } from 'expo-status-bar';
import { Component, useEffect, useState } from 'react';
import { AppState, BackHandler, Image, KeyboardAvoidingView, Linking, Modal, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import Constants from 'expo-constants';

import { createRealAdapter } from './app/real/adapter';
import { resolveClientConfig } from './app/real/config';
import { productionTransport } from './app/real/transport';
import { scopedStorage } from './app/lib/auth/storage';
import { activePresentationTenant, initialBinding } from './app/tenant/binding';
import { scanCameraPayload } from './app/tenant/scanner';
import { createTrustedBindingStorage } from './app/tenant/storage';
import { TempleQrCamera } from './app/tenant/camera_surface';
import { copy, oauthErrorPhases } from './app/ui/copy';
import { emptyFeedback, errorFeedback, feedbackForNavigation, noticeFeedback } from './app/ui/feedback';
import { Button, FormInput, Notice, Section } from './app/ui/primitives';
import { paletteFor } from './app/ui/theme';
import { createOAuthController } from './app/oauth/transaction';
import { createExpoOAuthRuntime } from './app/oauth/runtime';
import { resolveHardwareBack } from './app/tenant/back';
import { createInput, offeringCatalog, preparedRegistration, quantityInputValue, selectRegistrant, updateInput } from './app/account/registration_authority';
import { accountMenu, registrationCaption } from './app/account/screen_model';

// Everything below runs before React exists. Anything that throws here kills
// the app instantly, with no screen and nothing to read -- which is exactly
// what happened on 2026-09-03, on an iPhone that cannot be attached to a Mac
// and cannot install the dev client. There was no way to find out why.
//
// So a failure is captured and rendered instead. This is not about one bug:
// iOS here is reachable only through TestFlight OTA, so a startup error that
// leaves no trace is permanently undiagnosable without this.
let bootFailure = null;
let clientConfig = null;
let trustedBindingStorage = null;
let adapter = null;
let oauthController = null;
try {
  clientConfig = resolveClientConfig(Constants.expoConfig?.extra || {});
  trustedBindingStorage = createTrustedBindingStorage({ store: scopedStorage, config: clientConfig });
  adapter = createRealAdapter({ config: clientConfig, store: scopedStorage, transport: productionTransport });
  const oauthRuntime = createExpoOAuthRuntime(clientConfig.oauthReturnUrl);
  oauthController = createOAuthController({ adapter, expectedReturnUrl: clientConfig.oauthReturnUrl, createPkce: oauthRuntime.createPkce, openBrowser: oauthRuntime.openBrowser });
} catch (reason) {
  bootFailure = reason;
}

// Deliberately dependency-free: it must render even when the failure above was
// the thing that builds the palette, the copy, or the adapter.
function BootFailure({ failure, title, componentStack }) {
  const detail = [
    failure?.code ? `code: ${failure.code}` : null,
    failure?.message || String(failure),
    componentStack ? `in:${String(componentStack).split('\n').slice(0, 5).join('\n')}` : null,
    failure?.stack ? String(failure.stack).split('\n').slice(0, 5).join('\n') : null
  ].filter(Boolean).join('\n\n');
  // No SafeAreaProvider, no Shell, no palette, no copy. SafeAreaProvider renders
  // null until it has measured its insets, and at the root inside an error
  // boundary it can stay null -- which showed as a permanent white screen on
  // 2026-09-04 and hid the very error this exists to display. A plain View with
  // a hardcoded top inset cannot do that.
  return <View style={{ flex: 1, backgroundColor: '#1b1b1b', paddingTop: 64 }}><ScrollView contentContainerStyle={{ padding: 24, gap: 12 }}><Text selectable style={{ color: '#fff', fontSize: 20, fontWeight: '800' }}>{title}</Text><Text selectable style={{ color: '#ffb4b4', fontSize: 14, lineHeight: 20 }}>{detail}</Text><Text selectable style={{ color: '#9a9a9a', fontSize: 12, lineHeight: 18 }}>Screenshot this and send it to the developer. Press and hold to copy.</Text></ScrollView></View>;
}
const menuKeys = accountMenu();
// Rails returns a specific, already-localized validation message in
// details.base; the code-based fallback said "Please review the highlighted
// fields" in English on a Chinese UI, with nothing highlighted. Prefer the
// server's own text and fall back only when it has none.
const firstDetail = reason => {
  const details = reason?.details;
  if (!details || typeof details !== 'object') return null;
  const messages = details.base || Object.values(details).find(value => Array.isArray(value) && value.length);
  return Array.isArray(messages) && typeof messages[0] === 'string' ? messages[0] : null;
};
const errorMessage = reason => firstDetail(reason) || reason?.message || 'Something went wrong. Please try again.';

function AppBody() {
  // Before any hook, so a boot failure cannot be masked by a second error from
  // hooks reading state that never got built.
  if (bootFailure) return <BootFailure failure={bootFailure} title="TempleMate could not start" />;

  const [startup, setStartup] = useState(true); const [signedIn, setSignedIn] = useState(false); const [screen, setScreen] = useState('home');
  const [locale, setLocale] = useState('zh-TW'); const [dark, setDark] = useState(false); const [binding, setBinding] = useState(initialBinding()); const [data, setData] = useState(adapter.snapshot()); const [collections, setCollections] = useState('idle');
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [signup, setSignup] = useState({ name: '', email: '', password: '' }); const [recoveryEmail, setRecoveryEmail] = useState('');
  const [profileForm, setProfileForm] = useState({ english_name: '', native_name: '', phone: '', city: '' }); const [dependent, setDependent] = useState({ id: null, name: '', relationship: '家人' }); const [registration, setRegistration] = useState(null); const [album, setAlbum] = useState(null);
  const [supportMessage, setSupportMessage] = useState(''); const [closureConfirmation, setClosureConfirmation] = useState(''); const [pending, setPending] = useState(false); const [feedback, setFeedback] = useState(emptyFeedback());
  const [oauthState, setOauthState] = useState(oauthController.snapshot()); const [cameraOpen, setCameraOpen] = useState(false);
  // The server is authoritative for the temple's display name and it arrives
  // from bootstrap. There is no configured tenant to fall back to any more, so
  // a snapshot without a temple means no temple is loaded -- it used to
  // fabricate one from the compiled slug, which produced a bound state with an
  // empty id that the temple gate then accepted.
  const boundTenant = snapshot => {
    const temple = snapshot?.temple;
    if (!temple?.slug || !temple?.name) return initialBinding();
    return { state: 'bound', tenant: { id: temple.slug, name: temple.name }, error: null, source: 'qr' };
  };
  const t = copy[locale]; const palette = paletteFor(dark); const loadingText = t.loading;
  const showError = (message, owner = screen) => setFeedback(errorFeedback(message, owner));
  const dismissError = () => setFeedback(current => ({ ...current, error: null }));
  const navigate = destination => { setFeedback(current => feedbackForNavigation(current, destination)); setAlbum(null); setScreen(destination); };
  const error = feedback.error?.message; const notice = feedback.notice ? t[feedback.notice.key] : null;

  useEffect(() => {
    const timer = setTimeout(() => setStartup(false), 180); const resume = AppState.addEventListener('change', value => { if (value === 'active') setFeedback(emptyFeedback()); });
    const back = BackHandler.addEventListener('hardwareBackPress', () => { const next = resolveHardwareBack({ screen, cameraOpen, albumOpen: Boolean(album) }); if (!next.handled) return false; setCameraOpen(next.cameraOpen); setAlbum(null); if (next.screen !== screen) navigate(next.screen); return true; });
    return () => { clearTimeout(timer); resume.remove(); back.remove(); };
  }, [screen, cameraOpen, album]);
  useEffect(() => {
    let mounted = true;
    if (clientConfig.mode !== 'real') { setStartup(false); return () => { mounted = false; }; }
    (async () => {
      try {
        // The remembered temple is a fact about this device, not about the
        // session, so it is read before any sign-in is attempted. It used to be
        // loaded only when a session restored, which meant a signed-out launch
        // asked for the QR code again even though the binding was still stored.
        const remembered = await trustedBindingStorage.load();
        if (remembered && mounted) setBinding(remembered);
        const next = await adapter.restoreSession();
        if (next && mounted) {
          setData(next);
          // bootstrap ran only if a temple was loaded, so its temple is the
          // authority on the name; the stored record supplies it otherwise.
          setBinding(boundTenant(next).state === 'bound' ? boundTenant(next) : remembered || initialBinding());
          setSignedIn(true);
          // Collections are six temple-scoped requests. Signed in with no
          // temple is a real state -- it is the scanner -- so they wait.
          if (activePresentationTenant(boundTenant(next).state === 'bound' ? boundTenant(next) : remembered || initialBinding())) {
            setCollections('loading');
            const loaded = await adapter.loadCollections();
            if (mounted) { setData(loaded); setCollections('ready'); }
          }
        }
      } catch (reason) { if (mounted) { showError(errorMessage(reason)); setSignedIn(false); setCollections('failed'); } }
      finally { if (mounted) setStartup(false); }
    })();
    return () => { mounted = false; };
  }, []);
  useEffect(() => {
    let mounted = true;
    oauthController.restore().then(next => { if (mounted) setOauthState(next); }).catch(reason => { if (mounted) showError(errorMessage(reason)); });
    const callback = Linking.addEventListener('url', event => {
      oauthController.handleInterruptedReturn(event.url).then(async next => {
        if (!mounted) return;
        setOauthState(next);
        if (next.phase === 'authenticated' || next.phase === 'profile_required') { await completeSignIn({ profileRequired: next.phase === 'profile_required' }); }
      }).catch(reason => { if (mounted) showError(errorMessage(reason)); });
    });
    return () => { mounted = false; callback.remove(); };
  }, []);
  useEffect(() => {
    const preferences = data.preferences || {};
    if (['zh-TW', 'en'].includes(preferences.locale)) setLocale(preferences.locale);
    if (preferences.theme === 'dark' || preferences.mobile_theme_id === 'dark') setDark(true);
    if (preferences.theme === 'light' || preferences.mobile_theme_id === 'light') setDark(false);
  }, [data.preferences?.locale, data.preferences?.theme, data.preferences?.mobile_theme_id]);
  const run = async (action, { noticeOwner = screen, noticeKey = 'saved' } = {}) => { if (pending) return false; setPending(true); setFeedback(emptyFeedback()); try { const next = await action(); if (next && !next.outcome) setData(next); setFeedback(noticeFeedback(typeof noticeKey === 'function' ? noticeKey(next) : noticeKey, noticeOwner)); return true; } catch (reason) { showError(errorMessage(reason)); return false; } finally { setPending(false); } };
  // Every sign-in path used to reset the binding to initialBinding() on a
  // release build, throwing away a temple that was still in storage. Startup
  // and sign-out were fixed first; this was the third place, found only because
  // the Director signed out and back in rather than restarting.
  const bindingAfterSignIn = async () => {
    const remembered = await trustedBindingStorage.load();
    if (remembered) return remembered;
    return boundTenant(adapter.snapshot());
  };
  // Everything a successful sign-in must do, in one place. There were four
  // paths doing four different subsets: the password path loaded the
  // collections, none of the three OAuth paths did, and one of them did not
  // even restore the binding. Signing in with Google therefore showed the
  // registrations that bootstrap returns and no offerings at all, while the
  // account website was fine -- it does not depend on this client-side load.
  const completeSignIn = async ({ profileRequired = false } = {}) => {
    setData(adapter.snapshot());
    setSignedIn(true);
    const loadedTemple = await bindingAfterSignIn();
    setBinding(loadedTemple);
    // Six temple-scoped requests. A patron signing in with no temple loaded
    // goes to the scanner, and asking for them there produced the error banner
    // that criterion 6 forbids.
    if (!activePresentationTenant(loadedTemple)) return;
    setCollections('loading');
    try {
      setData(await adapter.loadCollections());
      setCollections('ready');
    } catch (reason) {
      setCollections('failed');
      showError(errorMessage(reason));
    }
    if (profileRequired) navigate('profile');
  };

  const signIn = async () => { const ok = await run(async () => { await adapter.signIn({ email, password }); return adapter.snapshot(); }); if (ok) await completeSignIn(); };
  // Seeded at mount, before sign-in, when the snapshot is still empty -- so
  // the fields rendered blank for a user who has values. Re-sync whenever the
  // loaded profile changes (bootstrap, sign-in, OAuth, save). Depends on the
  // individual values rather than the user object, whose identity changes on
  // every snapshot and would re-run this constantly.
  const loadedUser = data.profile.user || {};
  useEffect(() => {
    setProfileForm({
      english_name: loadedUser.english_name || '', native_name: loadedUser.native_name || '',
      phone: loadedUser.phone || '', city: loadedUser.city || ''
    });
  }, [loadedUser.english_name, loadedUser.native_name, loadedUser.phone, loadedUser.city]);

  // Sign-out keeps the remembered temple. It is where the device is, not who is
  // holding it, and the release config pins the tenant anyway -- normalizedBinding
  // refuses any binding whose id is not config.tenantSlug, so a retained one
  // cannot point elsewhere. Making a patron find the QR code again just to sign
  // back in bought nothing.
  // Explicit, and the only way a device forgets its temple.
  const onUnbindTemple = async () => {
    await trustedBindingStorage.clear().catch(() => null);
    setBinding(initialBinding());
  };
  const signOut = () => { oauthController.clear('idle').then(setOauthState).catch(() => null); Promise.resolve(adapter.logout?.()).catch(() => null); setSignedIn(false); setScreen('home'); setFeedback(emptyFeedback()); };
  const beginOAuth = async provider => {
    if (pending) return; setPending(true); setFeedback(emptyFeedback());
    try {
      const next = await oauthController.begin(provider); setOauthState(next);
      if (next.phase === 'authenticated' || next.phase === 'profile_required') { await completeSignIn({ profileRequired: next.phase === 'profile_required' }); return; }
      if (oauthErrorPhases.has(next.phase)) showError(t.oauthOutcome[next.phase]);
    } catch (reason) { showError(errorMessage(reason)); }
    finally { setPending(false); }
  };
  const submitResolution = async (mode, fields) => {
    if (pending) return; setPending(true); setFeedback(emptyFeedback());
    try {
      const next = await oauthController.consumeResolution({ mode, ...fields }); setOauthState(next);
      if (next.phase === 'authenticated' || next.phase === 'profile_required') { await completeSignIn({ profileRequired: next.phase === 'profile_required' }); }
    } catch (reason) { showError(errorMessage(reason)); }
    finally { setPending(false); }
  };
  const updatePreference = async next => { const previous = { locale, dark }; const payload = { ...(next.locale ? { locale: next.locale } : {}), ...(next.theme ? { mobile_theme_id: next.theme } : {}) }; const ok = await run(async () => adapter.updatePreferences(payload)); if (ok) { if (next.locale) { setFeedback(emptyFeedback()); setLocale(next.locale); } if (next.theme) setDark(next.theme === 'dark'); } else { setLocale(previous.locale); setDark(previous.dark); } };
  const shared = { t, palette, locale, setLocale, dark, setDark, screen, setScreen: navigate, data, setData, binding, setBinding, profileForm, setProfileForm, dependent, setDependent, registration, setRegistration, album, setAlbum, supportMessage, setSupportMessage, closureConfirmation, setClosureConfirmation, pending, error, setError: message => message ? showError(message) : dismissError(), notice, run, signOut, onUnbindTemple, collections, loadingText, updatePreference, oauthState, cameraOpen, setCameraOpen };
  if (startup) return <Shell palette={palette}><View style={styles.center}><Text style={[styles.brand, { color: palette.text }]}>{t.appName}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{loadingText}</Text></View></Shell>;
  if (!signedIn) return oauthState.phase === 'account_resolution' ? <OAuthResolution {...shared} onSubmit={submitResolution} /> : <SignedOut {...shared} {...{ email, setEmail, password, setPassword, signup, setSignup, recoveryEmail, setRecoveryEmail, signIn, setSignedIn, beginOAuth }} />;
  if (!activePresentationTenant(binding)) return <TenantSetupGate {...shared} />;
  return <Shell palette={palette}><Header t={t} palette={palette} binding={binding} onSettings={() => navigate('settings')} onSignOut={signOut} /><Navigation {...shared} /><ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">{error && <Notice palette={palette} tone="error">{error}<Button label={t.retry} palette={palette} tone="secondary" onPress={dismissError} /></Notice>}{notice && <Notice palette={palette}>{notice}</Notice>}<AccountSurface {...shared} /></ScrollView></Shell>;
}

function Shell({ palette, children }) { return <SafeAreaProvider><SafeAreaView style={[styles.safe, { backgroundColor: palette.background }]}><StatusBar style={palette.statusBar} /><KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.fill}>{children}</KeyboardAvoidingView></SafeAreaView></SafeAreaProvider>; }
function Header({ t, palette, binding, onSettings, onSignOut }) { const activeTenant = activePresentationTenant(binding); return <View style={[styles.header, { borderBottomColor: palette.border }]}><View style={styles.headerCopy}><Text style={[styles.brandSmall, { color: palette.text }]}>{t.appName}</Text><Text numberOfLines={1} style={[styles.muted, { color: palette.textMuted }]}>{activeTenant ? `${t.connected} · ${activeTenant.name}` : t.notConnected}</Text></View><View style={styles.headerUtilities}>{activeTenant && <Button label={t.settings} palette={palette} tone="secondary" onPress={onSettings} />}<Button label={t.signOut} palette={palette} tone="secondary" onPress={onSignOut} /></View></View>; }
function Navigation({ t, palette, screen, setScreen }) { return <ScrollView horizontal accessibilityRole="tablist" style={[styles.navigationShell, { borderBottomColor: palette.border }]} contentContainerStyle={styles.navigation} showsHorizontalScrollIndicator={false}>{menuKeys.map(key => <Pressable accessibilityRole="tab" accessibilityState={{ selected: screen === key }} key={key} onPress={() => setScreen(key)} style={[styles.navItem, { borderColor: palette.border, backgroundColor: screen === key ? palette.primary : palette.inset }]}><Text style={{ color: screen === key ? palette.onPrimary : palette.text, fontWeight: '800' }}>{t[key]}</Text></Pressable>)}</ScrollView>; }

function TenantSetupGate({ t, palette, binding, setBinding, setData, cameraOpen, setCameraOpen, setError, signOut }) {
  // A scan loads the temple; it does not merely remember it. This used to save
  // the record and call setData(adapter.snapshot()) -- the snapshot exactly as
  // it already was, with no name and no collections. A compiled tenant hid
  // that, because both had already run at sign-in.
  const onCameraResult = async result => {
    setCameraOpen(false);
    if (!result) return;
    if (result.state === 'binding_failed') { setError(t.cameraInvalidQrRelease); return; }
    try { await trustedBindingStorage.save(result); } catch (_) { setError(t.cameraInvalidQrRelease); return; }
    setBinding(result);
    setCollections('loading');
    try {
      const loaded = await adapter.bootstrap();
      setData(loaded);
      // The server names the temple. Persist that, so a relaunch shows the name
      // rather than the bare record the scan could confirm but not describe.
      const named = boundTenant(loaded);
      if (named.state === 'bound') {
        setBinding(named);
        await trustedBindingStorage.save(named).catch(() => null);
      }
      setData(await adapter.loadCollections());
      setCollections('ready');
    } catch (reason) {
      setCollections('failed');
      showError(errorMessage(reason));
    }
  };

  return <Shell palette={palette}><Header t={t} palette={palette} binding={binding} onSignOut={signOut} /><ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled"><Section title={t.setupTemple} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{t.setupTempleDescription}</Text>{cameraOpen ? <TempleQrCamera mode={clientConfig.mode} t={t} palette={palette} isRelease onCancel={onCameraResult} onScan={payload => scanCameraPayload({ mode: clientConfig.mode, payload, config: clientConfig, transport: productionTransport })} /> : <Button label={t.scanCodeRelease} palette={palette} onPress={() => setCameraOpen(true)} />}</Section></ScrollView></Shell>;
}

function SignedOut({ t, palette, locale, setLocale, dark, setDark, screen, setScreen, email, setEmail, password, setPassword, signup, setSignup, recoveryEmail, setRecoveryEmail, pending, error, setError, notice, run, signIn, setSignedIn, beginOAuth, oauthState }) {
  const create = screen === 'signup'; const recovery = screen === 'recovery'; const signUp = async () => { const ok = await run(() => adapter.signUp(signup)); if (ok) setSignedIn(true); };
  return <Shell palette={palette}><ScrollView contentContainerStyle={styles.auth} keyboardShouldPersistTaps="handled"><Text style={[styles.brand, { color: palette.text }]}>{t.appName}</Text><Text style={[styles.lead, { color: palette.text }]}>{create ? t.createAccount : recovery ? t.forgotPassword : t.signIn}</Text><Notice palette={palette} tone="info">{t.realAccount}</Notice>{!create && !recovery && <><Notice palette={palette} tone="info">{t.oauthBrowserNotice}</Notice><FormInput label={t.email} value={email} onChangeText={setEmail} autoCapitalize="none" palette={palette} /><FormInput label={t.password} value={password} onChangeText={setPassword} secureTextEntry autoCapitalize="none" palette={palette} /><Button label={pending ? '…' : t.signIn} palette={palette} onPress={signIn} disabled={pending} /><Button label={pending ? '…' : t.googleSignIn} palette={palette} tone="secondary" onPress={() => beginOAuth('google')} disabled={pending} /><Button label={pending ? '…' : t.appleSignIn} palette={palette} tone="secondary" onPress={() => beginOAuth('apple')} disabled={pending} /><Text style={[styles.muted, { color: palette.textMuted }]}>{t.oauthOutcome[oauthState.phase] || t.oauthOutcome.idle}</Text><Button label={t.createAccount} palette={palette} tone="secondary" onPress={() => setScreen('signup')} /><Button label={t.forgotPassword} palette={palette} tone="secondary" onPress={() => setScreen('recovery')} /></>}{create && <><Notice palette={palette} tone="info">{t.signupNotice}</Notice><FormInput label={t.name} value={signup.name} onChangeText={name => setSignup({ ...signup, name })} palette={palette} /><FormInput label={t.email} value={signup.email} onChangeText={emailValue => setSignup({ ...signup, email: emailValue })} autoCapitalize="none" palette={palette} /><FormInput label={t.password} value={signup.password} onChangeText={passwordValue => setSignup({ ...signup, password: passwordValue })} secureTextEntry autoCapitalize="none" palette={palette} /><Button label={pending ? '…' : t.createAccount} palette={palette} onPress={signUp} disabled={pending} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('home')} /></>}{recovery && <><Notice palette={palette} tone="info">{t.recoveryNotice}</Notice><FormInput label={t.email} value={recoveryEmail} onChangeText={setRecoveryEmail} autoCapitalize="none" palette={palette} /><Button label={pending ? '…' : t.forgotPassword} palette={palette} onPress={() => run(() => adapter.recoverPassword({ email: recoveryEmail }))} disabled={pending} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('home')} /></>}{error && <Notice palette={palette} tone="error">{error}<Button label={t.retry} palette={palette} tone="secondary" onPress={() => setError(null)} /></Notice>}{notice && <Notice palette={palette}>{notice}</Notice>}<Preferences {...{ t, palette, locale, setLocale, dark, setDark }} /></ScrollView></Shell>;
}

// Shown when app/oauth/transaction.js's exchange hits account_resolution_required
// (real identity, no matching/linkable account yet). Two paths mirroring the
// web equivalent (account/oauth_resolutions_controller.rb): link an existing
// account by password, or create a new one. Submission is wired through
// oauthController.consumeResolution via submitResolution in App() -- the
// actual Rails endpoint doesn't exist yet (adapter.consumeOAuthResolution is
// a deliberate stub pending Control A's contract), so this reaches a clear
// "not yet available" error at the last step rather than guessing a URL.
function OAuthResolution({ t, palette, oauthState, pending, error, setError, onSubmit }) {
  const [mode, setMode] = useState(null);
  // Prefill from what Google/Apple already told us (oauthState.hints), so a
  // patron confirms rather than retypes. Both stay editable -- the server
  // reads whatever is submitted, not the hint.
  const hints = oauthState.hints || {};
  const [email, setEmail] = useState(hints.email || ''); const [password, setPassword] = useState(''); const [name, setName] = useState(hints.name || ''); const [termsAccepted, setTermsAccepted] = useState(false);
  return <Shell palette={palette}><ScrollView contentContainerStyle={styles.auth} keyboardShouldPersistTaps="handled"><Text style={[styles.brand, { color: palette.text }]}>{t.appName}</Text><Text style={[styles.lead, { color: palette.text }]}>{oauthState.provider === 'apple' ? t.appleSignIn : t.googleSignIn}</Text><Notice palette={palette} tone="info">{t.oauthResolutionIntro}</Notice>
    {!mode && <><Button label={t.oauthResolutionExisting} palette={palette} onPress={() => setMode('existing')} /><Text style={[styles.muted, { color: palette.textMuted }]}>{t.oauthResolutionExistingDescription}</Text><Button label={t.oauthResolutionNew} palette={palette} onPress={() => setMode('new')} /><Text style={[styles.muted, { color: palette.textMuted }]}>{t.oauthResolutionNewDescription}</Text></>}
    {mode === 'existing' && <><FormInput label={t.email} value={email} onChangeText={setEmail} autoCapitalize="none" palette={palette} /><FormInput label={t.password} value={password} onChangeText={setPassword} secureTextEntry autoCapitalize="none" palette={palette} /><Button label={pending ? '…' : t.oauthResolutionLink} palette={palette} disabled={pending} onPress={() => onSubmit('existing', { email, password })} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setMode(null)} /></>}
    {mode === 'new' && <><FormInput label={t.email} value={email} onChangeText={setEmail} autoCapitalize="none" palette={palette} /><FormInput label={t.name} value={name} onChangeText={setName} palette={palette} /><FormInput label={t.password} value={password} onChangeText={setPassword} secureTextEntry autoCapitalize="none" palette={palette} /><Button label={(termsAccepted ? '☑ ' : '☐ ') + t.termsAccept} palette={palette} tone="secondary" onPress={() => setTermsAccepted(!termsAccepted)} /><Button label={pending ? '…' : t.oauthResolutionCreate} palette={palette} disabled={pending || !termsAccepted} onPress={() => onSubmit('new', { email, password, name, termsAccepted })} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setMode(null)} /></>}
    {error && <Notice palette={palette} tone="error">{error}<Button label={t.retry} palette={palette} tone="secondary" onPress={() => setError(null)} /></Notice>}
  </ScrollView></Shell>;
}

function AccountSurface(props) {
  // loadingText is defined in AppBody and AccountSurface is a top-level
  // function, so it was never in scope here -- a ReferenceError waiting for any
  // render where collections === 'loading'. It never fired because an unbound
  // release build stopped at TenantSetupGate instead of reaching this surface;
  // making the temple survive a restart removed the thing that was hiding it.
  const { screen, t, palette, data, binding, setBinding, profileForm, setProfileForm, dependent, setDependent, registration, setRegistration, album, setAlbum, supportMessage, setSupportMessage, closureConfirmation, setClosureConfirmation, pending, setScreen, run, collections, loadingText, onUnbindTemple } = props;
  if (screen === 'home') return <><Section title={t.account} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{t.welcome}{data.profile.name}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{data.registrations.length} {t.registrations} · {data.dependents.length} {t.dependents}</Text></Section><Section title={t.templeConnection} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{activePresentationTenant(binding)?.name || t.notConnected}</Text></Section><Section title={t.certificates} palette={palette}>{collections === 'loading' && <Text style={[styles.muted, { color: palette.textMuted }]}>{loadingText}</Text>}{collections === 'failed' && <Notice palette={palette} tone="error">{t.collectionFailed}</Notice>}{data.certificates.length ? data.certificates.map(item => <Text key={item.id} style={[styles.body, { color: palette.text }]}>{item.certificateNumber || item.certificate_number || item.offering?.title || t.certificateFixture}</Text>) : <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyCertificates}</Text>}</Section></>;
  if (screen === 'profile') {
    // The four fields NativeProfileController permits, matching the web form
    // exactly. `notes` is deliberately absent: it was scaffold residue that
    // staff code read as contact detail, and was removed from both surfaces.
    const field = key => ({ value: profileForm[key], onChangeText: text => setProfileForm({ ...profileForm, [key]: text }), palette });
    return <Section title={t.profile} palette={palette}>
      <Text style={[styles.muted, { color: palette.textMuted }]}>{t.email}: {data.profile.email}</Text>
      <FormInput label={t.nativeName} {...field('native_name')} />
      <FormInput label={t.englishName} {...field('english_name')} />
      <FormInput label={t.phone} {...field('phone')} />
      <FormInput label={t.city} {...field('city')} />
      <Button label={t.save} palette={palette} disabled={pending} onPress={() => run(() => adapter.updateProfile(profileForm))} />
    </Section>;
  }
  if (screen === 'dependents') return <Section title={t.dependents} palette={palette}>{collections === 'loading' && <Text style={[styles.muted, { color: palette.textMuted }]}>{loadingText}</Text>}{data.dependents.length === 0 && <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyDependents}</Text>}{data.dependents.map(item => <ListCard key={item.id} palette={palette} title={`${item.name} · ${item.relationship}`} onPress={() => setDependent({ id: item.id, name: item.name, relationship: item.relationship })} />)}<FormInput label={t.name} value={dependent.name} onChangeText={name => setDependent({ ...dependent, name })} palette={palette} /><FormInput label={t.relationship} value={dependent.relationship} onChangeText={relationship => setDependent({ ...dependent, relationship })} palette={palette} /><Button label={dependent.id ? t.update : t.add} palette={palette} disabled={pending} onPress={async () => { const ok = await run(() => dependent.id ? adapter.updateDependent(dependent.id, dependent) : adapter.createDependent(dependent)); if (ok) setDependent({ id: null, name: '', relationship: '家人' }); }} /><Button label={t.delete} palette={palette} tone="danger" disabled={!dependent.id || pending} onPress={async () => { const ok = await run(() => adapter.deleteDependent(dependent.id)); if (ok) setDependent({ id: null, name: '', relationship: '家人' }); }} /></Section>;
  const registrationSave = async () => {
    const ok = await run(() => registration.id
      ? adapter.updateRegistration(registration.id, updateInput(registration))
      : adapter.createRegistration(createInput(registration)));
    if (ok) { setRegistration(null); setScreen('registrations'); }
  };

  // Filling in a registration is a focused task, so the list of existing ones
  // steps aside. It used to render above the form, which meant tapping 登記 on
  // an offering dropped you below every registration you already had.
  if (screen === 'registrations' && registration) return <Section title={t.registrations} palette={palette}><RegistrationForm {...{ t, palette, registration, setRegistration, data, pending, run, setScreen }} onSave={registrationSave} /></Section>;
  if (screen === 'registrations') return <Section title={t.registrations} palette={palette}>{collections === 'loading' && <Text style={[styles.muted, { color: palette.textMuted }]}>{loadingText}</Text>}{data.registrations.length === 0 && <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyRegistrations}</Text>}{data.registrations.map(item => <ListCard key={item.id} palette={palette} title={`${item.offering.title} · ${item.registrantName}`} caption={registrationCaption(t, item)} disabled={item.readOnly} onPress={async () => { if (item.readOnly) return; let edit; const ok = await run(async () => { edit = await adapter.editRegistration(item.id); return null; }); if (ok) { const record = edit.registration || item; setRegistration({ ...preparedRegistration({ offering: record.offering || item.offering, registration: record, registrants: edit.registrants || [], snapshot: data }), id: item.id }); } }} />)}{!registration && <><Text style={[styles.muted, { color: palette.textMuted }]}>{t.registrationDiscoverHint}</Text><Button label={t.discoverOfferings} palette={palette} onPress={() => setScreen('discover')} /></>}</Section>;
  if (screen === 'discover') { const offerings = offeringCatalog(data); const start = async offering => { let prepared; const ok = await run(async () => { prepared = await adapter.newRegistration({ offering: offering.slug, accountAction: offering.account_action }); return null; }); if (ok) { if (prepared.can_register === false) { setRegistration(null); setScreen('registrations'); setFeedback(noticeFeedback('alreadyRegistered', 'registrations')); return; } setRegistration(preparedRegistration({ offering: prepared.offering, registration: prepared.registration, registrants: prepared.registrants, snapshot: data })); setScreen('registrations'); } }; return <><Section title={t.activity} palette={palette}><OfferingList items={offerings.filter(item => item.account_action === 'event' || item.account_action === 'gathering')} palette={palette} t={t} onSelect={start} /></Section><Section title={t.services} palette={palette}><OfferingList items={offerings.filter(item => item.account_action === 'service')} palette={palette} t={t} onSelect={start} /></Section></>; }
  // Gallery is its own screen, and an album is a step inside it. Two levels,
  // because a temple album runs to twenty photos or more: the list shows one
  // cover each, and only the album a patron actually opened loads its own.
  if (screen === 'gallery' && album) return <AlbumScreen {...{ t, palette, album, onBack: () => setAlbum(null) }} />;
  if (screen === 'gallery') return <Section title={t.gallery} palette={palette}>{collections === 'loading' && <Text style={[styles.muted, { color: palette.textMuted }]}>{loadingText}</Text>}{data.gallery.length === 0 && collections !== 'loading' && <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyCollection}</Text>}{data.gallery.map(item => <AlbumCard key={item.id} palette={palette} album={item} caption={albumCaption(t, item)} onPress={() => setAlbum(item)} />)}</Section>;
  if (screen === 'settings') return <Section title={t.settings} palette={palette}><Preferences {...props} /><Text style={[styles.subhead, { color: palette.text }]}>{t.privacyHelp}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{t.assistanceDescription}</Text><Button label={t.assistance} palette={palette} tone="secondary" onPress={() => setScreen('assistance')} /><Button label={t.privacyRequest} palette={palette} tone="secondary" onPress={() => setScreen('privacy')} /><Button label={t.closeAccount} palette={palette} tone="danger" onPress={() => setScreen('closure')} /><Text style={[styles.subhead, { color: palette.text }]}>{t.templeConnection}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{activePresentationTenant(binding)?.name}</Text>{binding.state === 'bound' && <Button label={t.unbindTemple} palette={palette} tone="secondary" onPress={onUnbindTemple} />}</Section>;
  if (screen === 'assistance') return <Section title={t.assistance} palette={palette}><Notice palette={palette} tone="info">{t.assistanceDestination}</Notice><FormInput label={t.message} value={supportMessage} onChangeText={setSupportMessage} maxLength={280} palette={palette} /><Text style={[styles.muted, { color: palette.textMuted }]}>{supportMessage.length}/280</Text><Button label={t.send} palette={palette} onPress={async () => { const ok = await run(() => adapter.submitAssistance({ channel: 'profile', message: supportMessage }), { noticeOwner: 'settings', noticeKey: result => result?.outcome === 'duplicate' ? 'assistanceDuplicate' : result?.assistance?.outcome === 'fixture' ? 'assistanceFixtureSubmitted' : 'assistanceCreated' }); if (ok) setScreen('settings'); }} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('settings')} /></Section>;
  if (screen === 'privacy') return <Section title={t.privacyRequest} palette={palette}><Button label={t.exportData} palette={palette} onPress={() => run(() => adapter.requestPrivacy({ kind: 'export' }))} /><Button label={t.deletionRequest} palette={palette} tone="danger" onPress={() => run(() => adapter.requestPrivacy({ kind: 'deletion' }))} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('settings')} /></Section>;
  if (screen === 'closure') return <Section title={t.closeAccount} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{t.closeDescription}</Text><FormInput label="CLOSE" value={closureConfirmation} onChangeText={setClosureConfirmation} autoCapitalize="characters" palette={palette} /><Button label={t.closeAccount} palette={palette} tone="danger" onPress={async () => { const ok = await run(() => adapter.closeAccount({ confirmation: closureConfirmation })); if (ok) props.signOut(); }} /><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('settings')} /></Section>;
  if (screen === 'connection') return <Section title={t.templeConnection} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{activePresentationTenant(binding)?.name || t.notConnected}</Text><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('home')} /></Section>;
  return <Section title={t.notFound} palette={palette}><Text style={[styles.body, { color: palette.text }]}>{t.notFoundDescription}</Text><Button label={t.back} palette={palette} tone="secondary" onPress={() => setScreen('home')} /></Section>;
}

function Preferences({ t, palette, locale, dark, updatePreference }) { return <View style={styles.preferences}><Text style={[styles.label, { color: palette.text }]}>{t.language}</Text><View style={styles.choiceRow}><Button label="繁中" palette={palette} tone="secondary" onPress={() => updatePreference({ locale: 'zh-TW' })} /><Button label="English" palette={palette} tone="secondary" onPress={() => updatePreference({ locale: 'en' })} /></View><Text style={[styles.label, { color: palette.text }]}>{t.appearance}</Text><Button label={dark ? t.light : t.dark} palette={palette} tone="secondary" onPress={() => updatePreference({ theme: dark ? 'light' : 'dark' })} /></View>; }
// An image appears only when the offering has one of its own -- the server
// never sends the temple fallback here, so a picture means "this one has a
// picture" rather than filling every row with the same default.
// Collapses to nothing if the image cannot be decoded -- an SVG URL (React
// Native cannot render one), a 404, a dead host. Without this the row still
// reserves the full image height and draws an empty band, which reads as a
// broken screen rather than as an offering with no picture. No image and an
// unrenderable image should look the same.
function OfferingImage({ uri }) {
  const [failed, setFailed] = useState(false);
  if (!uri || failed) return null;
  return <Image source={{ uri }} style={styles.offeringImage} resizeMode="cover" onError={() => setFailed(true)} />;
}
function OfferingList({ items, palette, t, onSelect }) { return items.length ? items.map(item => <View key={item.id} style={styles.preferences}><OfferingImage uri={item.hero_image_url} /><Text style={[styles.body, { color: palette.text }]}>{item.title}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{formatMoney(item.price_cents, item.currency)}</Text><Button label={t.register} palette={palette} onPress={() => onSelect(item)} /></View>) : <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyCollection}</Text>; }
function RegistrationForm({ t, palette, registration, setRegistration, pending, setScreen, onSave }) { const { offering, registrants } = registration; const change = key => value => setRegistration({ ...registration, registration: { ...registration.registration, [key]: value } }); return <View style={styles.preferences}><Text style={[styles.subhead, { color: palette.text }]}>{offering.title}</Text><Text style={[styles.muted, { color: palette.textMuted }]}>{formatMoney(offering.price_cents, offering.currency)}</Text><Text style={[styles.label, { color: palette.text }]}>{t.registrant}</Text>{registrants.map(choice => <Button key={`${choice.scope}-${choice.id}`} label={choice.label} palette={palette} tone={registration.registration.registrant_scope === choice.scope && (choice.scope === 'self' || String(registration.registration.dependent_id) === String(choice.id)) ? 'primary' : 'secondary'} onPress={() => setRegistration(selectRegistrant(registration, choice))} />)}<FormInput label={t.quantity} value={quantityInputValue(registration.registration.quantity)} onChangeText={change('quantity')} palette={palette} /><FormInput label={t.contactName} value={registration.registration.contact_name || ''} onChangeText={change('contact_name')} palette={palette} /><FormInput label={t.phone} value={registration.registration.contact_phone || ''} onChangeText={change('contact_phone')} palette={palette} /><FormInput label={t.email} value={registration.registration.contact_email || ''} onChangeText={change('contact_email')} autoCapitalize="none" palette={palette} /><FormInput label={t.householdNotes} value={registration.registration.household_notes || ''} onChangeText={change('household_notes')} palette={palette} /><FormInput label={t.arrivalWindow} value={registration.registration.arrival_window || ''} onChangeText={change('arrival_window')} palette={palette} /><FormInput label={t.ceremonyNotes} value={registration.registration.ceremony_notes || ''} onChangeText={change('ceremony_notes')} palette={palette} /><Button label={registration.id ? t.update : t.createRegistration} palette={palette} disabled={pending} onPress={onSave} /><Button label={t.cancel} palette={palette} tone="secondary" onPress={() => { setRegistration(null); setScreen('registrations'); }} /></View>; }
function formatMoney(amount, currency) { return currency === 'TWD' ? `NT$${(Number(amount || 0) / 100).toLocaleString('en-US')}` : `${currency || ''} ${Number(amount || 0).toLocaleString()}`.trim(); }
function ListCard({ palette, title, caption, onPress, disabled }) { return <Pressable accessibilityRole="button" accessibilityState={{ disabled: Boolean(disabled) }} disabled={disabled} onPress={onPress} style={[styles.listCard, { backgroundColor: palette.inset, borderColor: palette.border }, disabled && styles.disabled]}><Text style={[styles.body, { color: palette.text }]}>{title}</Text>{caption && <Text style={[styles.muted, { color: palette.textMuted }]}>{caption}</Text>}</Pressable>; }
// The album list: one card per album, its own first photo as the cover. This
// was a line of text at the bottom of Explore -- title and date, no photos, and
// item.date, a field this payload does not have, so even the date was blank.
function AlbumCard({ palette, album, caption, onPress }) {
  const cover = (album.photo_urls || [])[0];
  return <Pressable accessibilityRole="button" accessibilityLabel={album.title} onPress={onPress} style={[styles.albumCard, { backgroundColor: palette.inset, borderColor: palette.border }]}>
    {cover ? <Image source={{ uri: cover }} style={styles.albumCover} resizeMode="cover" /> : null}
    <View style={styles.albumCardCopy}>
      <Text style={[styles.body, { color: palette.text }]}>{album.title}</Text>
      <Text style={[styles.muted, { color: palette.textMuted }]}>{caption}</Text>
    </View>
  </Pressable>;
}
// event_date, not date: the field the old text row read never existed on this
// payload. Sliced rather than parsed, because a Date would shift the day
// across timezones.
function albumCaption(t, item) {
  const count = (item.photo_urls || []).length;
  return [String(item.event_date || '').slice(0, 10), count ? `${count} ${t.photos}` : t.emptyAlbum].filter(Boolean).join(' · ');
}
// One album, as a contact sheet. Thumbnails rather than full-width images:
// twenty photos down a phone screen is a scroll, not an album, and the point
// here is to find the one worth opening.
function AlbumScreen({ t, palette, album, onBack }) {
  const [viewer, setViewer] = useState(null);
  const photos = album.photo_urls || [];
  return <Section title={album.title} palette={palette}>
    <Text style={[styles.muted, { color: palette.textMuted }]}>{albumCaption(t, album)}</Text>
    {album.body ? <Text style={[styles.body, { color: palette.text }]}>{album.body}</Text> : null}
    {photos.length
      ? <View style={styles.galleryStrip}>{photos.map((uri, index) => <Pressable key={`${album.id}-${index}`} accessibilityRole="imagebutton" accessibilityLabel={`${album.title} ${index + 1}`} onPress={() => setViewer({ index })} style={styles.galleryThumb}><Image source={{ uri }} style={styles.galleryThumbImage} resizeMode="cover" /></Pressable>)}</View>
      : <Text style={[styles.muted, { color: palette.textMuted }]}>{t.emptyAlbum}</Text>}
    <Button label={t.backToAlbums} palette={palette} tone="secondary" onPress={onBack} />
    <PhotoViewer viewer={viewer} photos={photos} title={album.title} palette={palette} t={t} onChange={setViewer} onClose={() => setViewer(null)} />
  </Section>;
}
// Contained, not cropped: the contact sheet crops to a square so the album can
// be scanned, and the whole point of opening one is to see it as it was taken.
// onRequestClose is what makes Android back close the photo instead of leaving
// the album underneath it.
function PhotoViewer({ viewer, photos, title, palette, t, onChange, onClose }) {
  if (!viewer) return null;
  const total = photos.length;
  const step = offset => onChange({ index: (viewer.index + offset + total) % total });
  return <Modal visible transparent animationType="fade" onRequestClose={onClose}>
    <View style={styles.photoViewer}>
      <Image source={{ uri: photos[viewer.index] }} style={styles.photoViewerImage} resizeMode="contain" />
      <Text style={styles.photoViewerCaption}>{`${title} · ${viewer.index + 1}/${total}`}</Text>
      <View style={styles.photoViewerBar}>
        {total > 1 && <Button label={t.previousPhoto} palette={palette} tone="secondary" onPress={() => step(-1)} />}
        <Button label={t.closePhoto} palette={palette} onPress={onClose} />
        {total > 1 && <Button label={t.nextPhoto} palette={palette} tone="secondary" onPress={() => step(1)} />}
      </View>
    </View>
  </Modal>;
}

const styles = StyleSheet.create({ safe: { flex: 1 }, fill: { flex: 1 }, center: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 10, padding: 24 }, auth: { padding: 24, gap: 14, flexGrow: 1, justifyContent: 'center' }, header: { minHeight: 78, paddingHorizontal: 18, paddingVertical: 12, borderBottomWidth: 1, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 12 }, headerCopy: { flex: 1 }, headerUtilities: { flexDirection: 'row', gap: 8 }, brand: { fontSize: 34, fontWeight: '900', letterSpacing: -0.6 }, brandSmall: { fontSize: 22, fontWeight: '900' }, lead: { fontSize: 17, fontWeight: '700' }, muted: { fontSize: 14, lineHeight: 20 }, body: { fontSize: 16, lineHeight: 23 }, label: { fontSize: 14, fontWeight: '800' }, subhead: { fontSize: 16, fontWeight: '800', marginTop: 4 }, navigationShell: { flexGrow: 0, borderBottomWidth: 1 }, navigation: { flexDirection: 'row', flexWrap: 'nowrap', alignItems: 'center', gap: 8, paddingHorizontal: 14, paddingVertical: 12 }, navItem: { minHeight: 40, paddingHorizontal: 12, justifyContent: 'center', borderRadius: 20, borderWidth: 1 }, content: { padding: 16, gap: 14, paddingBottom: 32 }, listCard: { padding: 13, gap: 4, borderWidth: 1, borderRadius: 12 }, choiceRow: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' }, preferences: { gap: 9 }, offeringImage: { width: '100%', height: 132, borderRadius: 12 }, albumCard: { borderWidth: 1, borderRadius: 12, overflow: 'hidden' }, albumCover: { width: '100%', height: 148 }, albumCardCopy: { padding: 13, gap: 4 }, galleryStrip: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 }, galleryThumb: { width: 96, height: 96, borderRadius: 10, overflow: 'hidden' }, galleryThumbImage: { width: '100%', height: '100%' }, photoViewer: { flex: 1, backgroundColor: 'rgba(0,0,0,0.92)', alignItems: 'center', justifyContent: 'center', gap: 14, padding: 18 }, photoViewerImage: { width: '100%', flex: 1 }, photoViewerCaption: { color: '#f4f4f5', fontSize: 14 }, photoViewerBar: { flexDirection: 'row', gap: 10, flexWrap: 'wrap', justifyContent: 'center' }, disabled: { opacity: 0.52 } });

// The boot guard covers module scope only. This covers everything after it --
// a throw during render, or in a lifecycle -- which is where the 2026-09-04
// crash actually lived: the bundle loaded, the sign-in screen flashed, and then
// it died with nothing to read.
//
// Same reason as the boot guard: iOS here is reachable only through TestFlight
// OTA, with no Console.app and no dev client, so an error that leaves no trace
// on screen leaves no trace at all.
class AppErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { failure: null, componentStack: null };
  }

  static getDerivedStateFromError(failure) {
    return { failure };
  }

  // The component stack is the part worth having: it names which component
  // threw, which the error message alone often does not.
  componentDidCatch(failure, info) {
    this.setState({ componentStack: info?.componentStack || null });
  }

  render() {
    if (this.state.failure) return <BootFailure failure={this.state.failure} componentStack={this.state.componentStack} title="TempleMate hit an error" />;
    return this.props.children;
  }
}

export default function App() {
  return <AppErrorBoundary><AppBody /></AppErrorBoundary>;
}
