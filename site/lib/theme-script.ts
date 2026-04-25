export const themeScript = `
  (function() {
    try {
      var stored = localStorage.getItem('snapprice-theme');
      var theme = stored === 'light' ? 'light' : 'dark';
      document.documentElement.dataset.theme = theme;
    } catch (e) {
      document.documentElement.dataset.theme = 'dark';
    }
  })();
`;
