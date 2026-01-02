import { StyleSheet } from 'react-native';

const baseSpacing = 24;

const createPlaceholderStyles = (tokens) =>
  StyleSheet.create({
    safeArea: {
      flex: 1,
      backgroundColor: tokens.surface
    },
    scrollContent: {
      flexGrow: 1,
      paddingHorizontal: baseSpacing,
      paddingVertical: baseSpacing,
      backgroundColor: tokens.surface
    },
    hero: {
      marginBottom: baseSpacing
    },
    eyebrow: {
      color: tokens.textMuted,
      letterSpacing: 3,
      textTransform: 'uppercase',
      marginBottom: 8,
      fontWeight: '600'
    },
    title: {
      color: tokens.text,
      fontSize: 32,
      fontWeight: '700',
      marginBottom: 10
    },
    subtitle: {
      color: tokens.textMuted,
      fontSize: 16,
      lineHeight: 22
    },
    panel: {
      backgroundColor: tokens.surfaceRaised,
      borderRadius: 24,
      padding: baseSpacing,
      borderWidth: 1,
      borderColor: tokens.border
    },
    panelSpacing: {
      marginBottom: baseSpacing
    },
    panelTitle: {
      color: tokens.text,
      fontSize: 18,
      fontWeight: '700',
      marginBottom: 12
    },
    bodyText: {
      color: tokens.text,
      fontSize: 15,
      lineHeight: 22
    },
    caption: {
      color: tokens.textMuted,
      fontSize: 13,
      marginTop: 10
    },
    statusBadge: {
      marginTop: 16,
      alignSelf: 'flex-start',
      borderRadius: 999,
      paddingHorizontal: 14,
      paddingVertical: 6
    },
    statusBadgeReady: {
      backgroundColor: tokens.success
    },
    statusBadgeMuted: {
      backgroundColor: tokens.border
    },
    statusBadgeText: {
      color: tokens.surface,
      fontWeight: '600',
      fontSize: 12,
      letterSpacing: 1,
      textTransform: 'uppercase'
    },
    primaryButton: {
      marginTop: 16,
      borderRadius: 16,
      paddingVertical: 16,
      alignItems: 'center',
      backgroundColor: tokens.primary
    },
    primaryButtonText: {
      color: tokens.primaryForeground,
      fontWeight: '600',
      fontSize: 16
    },
    primaryButtonDisabled: {
      backgroundColor: tokens.surfaceMuted
    },
    primaryButtonPressed: {
      opacity: 0.9
    },
    credentialRow: {
      marginTop: 12
    },
    credentialLabel: {
      color: tokens.textMuted,
      fontSize: 13,
      marginBottom: 6
    },
    credentialValue: {
      color: tokens.text,
      fontSize: 16,
      fontWeight: '600',
      paddingVertical: 10,
      paddingHorizontal: 14,
      borderRadius: 14,
      backgroundColor: tokens.surfaceMuted,
      borderWidth: 1,
      borderColor: tokens.border
    },
    stepRow: {
      flexDirection: 'row',
      alignItems: 'flex-start',
      marginBottom: 14
    },
    stepIndex: {
      width: 28,
      height: 28,
      borderRadius: 14,
      textAlign: 'center',
      textAlignVertical: 'center',
      fontWeight: '700',
      color: tokens.text,
      backgroundColor: tokens.surfaceMuted,
      marginRight: 12,
      lineHeight: 28
    },
    stepCopy: {
      flex: 1,
      color: tokens.text,
      fontSize: 15,
      lineHeight: 22
    },
    actionsRow: {
      marginTop: baseSpacing,
      flexDirection: 'row',
      flexWrap: 'wrap'
    },
    secondaryButton: {
      borderRadius: 16,
      borderWidth: 1,
      borderColor: tokens.border,
      paddingVertical: 14,
      paddingHorizontal: 18,
      marginRight: 12,
      marginBottom: 12,
      backgroundColor: tokens.surfaceRaised
    },
    secondaryButtonText: {
      color: tokens.text,
      fontWeight: '600'
    },
    secondaryButtonPressed: {
      opacity: 0.85
    },
    footerNote: {
      marginTop: baseSpacing,
      color: tokens.textMuted,
      fontSize: 13,
      lineHeight: 20
    }
  });

export default createPlaceholderStyles;
