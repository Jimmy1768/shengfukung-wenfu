// An open album is a step inside the gallery, so back closes it and leaves the
// patron on the album list. Without this, backing out of one album dropped them
// on the home screen and they had to navigate in again for the next one.
const resolveHardwareBack = ({ screen, cameraOpen, albumOpen = false }) => {
  if (cameraOpen) return { handled: true, screen: 'home', cameraOpen: false, albumOpen: false };
  if (albumOpen) return { handled: true, screen, cameraOpen: false, albumOpen: false };
  if (screen !== 'home') return { handled: true, screen: 'home', cameraOpen: false, albumOpen: false };
  return { handled: false, screen, cameraOpen: false, albumOpen: false };
};

module.exports = { resolveHardwareBack };
