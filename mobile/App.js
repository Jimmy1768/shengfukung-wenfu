import { StatusBar } from 'expo-status-bar';
import Constants from 'expo-constants';
import { useEffect, useMemo, useState } from 'react';
import { Linking, Pressable, ScrollView, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

import { defaultThemeId, getTheme } from './theme/tokens';
import createPlaceholderStyles from './theme/styles/login';
import { loadThemePreference } from './app/lib/theme/storage';
import { resolveMobileTheme } from './app/lib/theme/resolver';

const getExtras = () => {
  const expoConfig = Constants?.expoConfig ?? Constants?.manifest ?? {};
  return expoConfig.extra ?? {};
};

const formatProviders = (providers = []) =>
  providers
    .map((provider) => provider.charAt(0).toUpperCase() + provider.slice(1))
    .join(', ');

export default function App() {
  const extras = useMemo(() => getExtras(), []);
  const expoConfig = Constants?.expoConfig ?? Constants?.manifest ?? {};
  const appName = expoConfig?.name || 'Golden Template Mobile';
  const [storedThemePreference, setStoredThemePreference] = useState(null);
  const [themePreferenceLoaded, setThemePreferenceLoaded] = useState(false);
  const resolvedTheme = useMemo(
    () =>
      resolveMobileTheme({
        userPreference: storedThemePreference,
        projectDefault: extras.defaultThemeId,
        hardcodedFallback: defaultThemeId
      }),
    [storedThemePreference, extras.defaultThemeId]
  );
  const themeId = resolvedTheme.themeId;
  const theme = getTheme(themeId);
  const tokens = theme.tokens;
  const styles = useMemo(() => createPlaceholderStyles(tokens), [tokens]);

  const marketingLinks = extras.marketingLinks || {};
  const demoCredentials = extras.demoCredentials || {};
  const oauthProviders = extras.oauth?.providers ?? [];
  const oauthConfigured = oauthProviders.length > 0;

  const quickActions = [
    { label: 'Open marketing site', url: marketingLinks.home },
    { label: 'Open marketing admin', url: marketingLinks.demo }
  ].filter((action) => !!action.url);

  const steps = [
    'Set MOBILE_API_BASE_URL and JWT paths before running dev-client or native builds.',
    'Provide OAUTH_* env vars (or swap this block) once a client requests OAuth sign-in.',
    'Replace this placeholder with your navigation + screens after mobile scope is approved.'
  ];

  const handleLinkPress = (url) => {
    if (!url) return;
    Linking.openURL(url).catch(() => {
      console.warn(`Unable to open ${url}`);
    });
  };

  const primaryButtonLabel = oauthConfigured ? 'Launch OAuth stub' : 'OAuth not available';

  useEffect(() => {
    let isMounted = true;

    loadThemePreference()
      .then((value) => {
        if (!isMounted) return;
        setStoredThemePreference(value);
      })
      .finally(() => {
        if (!isMounted) return;
        setThemePreferenceLoaded(true);
      });

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.safeArea}>
        <StatusBar style={theme.mode === 'dark' ? 'light' : 'dark'} />
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.hero}>
            <Text style={styles.eyebrow}>Expo starter</Text>
            <Text style={styles.title}>{appName}</Text>
            <Text style={styles.subtitle}>
              Keep this skeleton light until a client signs off on mobile scope. Everything you need to start building is still
              in the repo.
            </Text>
            <Text style={styles.caption}>
              Theme: {theme.label} ({themeId}) · Source:{' '}
              {themePreferenceLoaded ? resolvedTheme.source.replace(/_/g, ' ') : 'loading'}
            </Text>
          </View>

          <View style={[styles.panel, styles.panelSpacing]}>
            <Text style={styles.panelTitle}>Authentication placeholder</Text>
            <Text style={styles.bodyText}>
              {oauthConfigured
                ? 'OAuth credentials detected. Wire this into your auth flow when you build the real experience.'
                : 'OAuth providers are not configured yet. Add client IDs and secrets when you’re ready to demo sign-in.'}
            </Text>
            <View style={[styles.statusBadge, oauthConfigured ? styles.statusBadgeReady : styles.statusBadgeMuted]}>
              <Text style={styles.statusBadgeText}>
                {oauthConfigured ? 'OAuth ready' : 'OAuth unavailable'}
              </Text>
            </View>
            <Text style={styles.caption}>
              {oauthConfigured
                ? `Configured providers: ${formatProviders(oauthProviders)}`
                : 'Set env vars such as OAUTH_GOOGLE_CLIENT_ID / _SECRET before building to enable SSO.'}
            </Text>
            <Pressable
              onPress={oauthConfigured ? () => console.log('Stub OAuth action') : undefined}
              style={({ pressed }) => [
                styles.primaryButton,
                !oauthConfigured && styles.primaryButtonDisabled,
                pressed && oauthConfigured && styles.primaryButtonPressed
              ]}
              disabled={!oauthConfigured}
            >
              <Text style={styles.primaryButtonText}>{primaryButtonLabel}</Text>
            </Pressable>
          </View>

          <View style={[styles.panel, styles.panelSpacing]}>
            <Text style={styles.panelTitle}>Seeded admin credentials</Text>
            <Text style={styles.caption}>Mirrors PROJECT_DEFAULT_ADMIN_* env vars.</Text>
            <View style={styles.credentialRow}>
              <Text style={styles.credentialLabel}>Email</Text>
              <Text style={styles.credentialValue}>{demoCredentials.email || 'admin@example.com'}</Text>
            </View>
            <View style={styles.credentialRow}>
              <Text style={styles.credentialLabel}>Password</Text>
              <Text style={styles.credentialValue}>{demoCredentials.password || 'Password123!'}</Text>
            </View>
          </View>

          <View style={[styles.panel, styles.panelSpacing]}>
            <Text style={styles.panelTitle}>Next steps</Text>
            {steps.map((step, index) => (
              <View style={styles.stepRow} key={step}>
                <Text style={styles.stepIndex}>{index + 1}</Text>
                <Text style={styles.stepCopy}>{step}</Text>
              </View>
            ))}
          </View>

          {quickActions.length > 0 && (
            <View style={styles.actionsRow}>
              {quickActions.map((action) => (
                <Pressable
                  key={action.label}
                  onPress={() => handleLinkPress(action.url)}
                  style={({ pressed }) => [
                    styles.secondaryButton,
                    pressed && styles.secondaryButtonPressed
                  ]}
                >
                  <Text style={styles.secondaryButtonText}>{action.label}</Text>
                </Pressable>
              ))}
            </View>
          )}

          <Text style={styles.footerNote}>
            Replace this placeholder when you are ready. Auth helpers, SecureStore, and locale scaffolding stay in the repo so
            you can hook them up later.
          </Text>
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
