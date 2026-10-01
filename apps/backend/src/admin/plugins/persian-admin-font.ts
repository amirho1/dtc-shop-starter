const adminFontCss = `
  @font-face {
    font-family: "Vazirmatn";
    src: url("/static/fonts/Vazirmatn-VariableFont_wght.ttf") format("truetype");
    font-style: normal;
    font-weight: 100 900;
    font-display: swap;
  }

  html,
  body,
  body :where(*:not(svg):not(svg *)) {
    font-family: "Vazirmatn", sans-serif !important;
  }
`

export const persianAdminFont = () => ({
  name: "persian-admin-font",
  transformIndexHtml: () => [
    {
      tag: "style",
      children: adminFontCss,
      injectTo: "head" as const,
    },
  ],
})
