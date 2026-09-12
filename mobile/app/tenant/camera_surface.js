import { useEffect, useRef, useState } from 'react';
import { Text, View } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';

import { createCameraPermissionController, createCameraSession } from './camera_session';
import { Button, Notice } from '../ui/primitives';

export function TempleQrCamera({ mode, onScan, onCancel, t, palette }) {
  // One set of strings. The demo halves of these pairs went with the dummy
  // client; there is no build that reads them any more.
  const invalidQrMessage = t.cameraInvalidQrRelease;
  const instructions = t.cameraInstructionsRelease;
  const [permission, requestPermission] = useCameraPermissions();
  const session = useRef(createCameraSession({ scanPayload: onScan })).current;
  const permissionController = useRef(createCameraPermissionController()).current;
  const [state, setState] = useState(() => session.open(permission));

  useEffect(() => {
    const next = session.open(permission);
    setState(next);
    if (permissionController.open(permission)) requestPermission();
  }, [permission, permissionController, requestPermission, session]);

  const cancel = () => { permissionController.close(); session.close(); onCancel(); };
  const retry = () => { if (permissionController.retry(permission)) requestPermission(); };
  const receive = async ({ data }) => {
    const next = await session.receive(data);
    setState(next);
    if (next.state === 'success') onCancel(next.result);
  };

  if (state.state === 'loading') return <Notice palette={palette} tone="info">{t.cameraPermissionLoading}</Notice>;
  if (state.state === 'denied' || state.state === 'blocked') return <View style={{ gap: 10 }}><Notice palette={palette} tone="error">{state.state === 'blocked' ? t.cameraPermissionBlocked : t.cameraPermissionDenied}</Notice>{state.state === 'denied' && <Button label={t.cameraPermissionRetry} palette={palette} onPress={retry} />}<Button label={t.cameraCancel} palette={palette} tone="secondary" onPress={cancel} /></View>;
  if (state.state === 'invalid') return <View style={{ gap: 10 }}><Notice palette={palette} tone="error">{invalidQrMessage}</Notice><Button label={t.cameraTryAgain} palette={palette} onPress={() => setState(session.open({ granted: true }))} /><Button label={t.cameraCancel} palette={palette} tone="secondary" onPress={cancel} /></View>;
  if (state.state === 'success' || state.state === 'validating') return <Notice palette={palette} tone="info">{t.cameraValidating}</Notice>;
  return <View style={{ gap: 10 }}><CameraView style={{ width: '100%', height: 300, borderRadius: 12, overflow: 'hidden' }} facing="back" barcodeScannerSettings={{ barcodeTypes: ['qr'] }} onBarcodeScanned={state.locked ? undefined : receive}><View style={{ padding: 12 }}><Text style={{ color: '#ffffff', fontWeight: '800' }}>{instructions}</Text></View></CameraView><Button label={t.cameraCancel} palette={palette} tone="secondary" onPress={cancel} /></View>;
}
