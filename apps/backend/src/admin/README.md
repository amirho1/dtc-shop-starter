# Admin Customizations

You can extend the Medusa Admin to add widgets and new pages. Your customizations interact with API routes to provide merchants with custom functionalities.

> Learn more about Admin Extensions in [this documentation](https://docs.medusajs.com/learn/fundamentals/admin).

## Example: Create a Widget

A widget is a React component that can be injected into an existing page in the admin dashboard.

For example, create the file `src/admin/widgets/product-widget.tsx` with the following content:

```tsx title="src/admin/widgets/product-widget.tsx"
import { defineWidgetConfig } from "@medusajs/admin-sdk"

// The widget
const ProductWidget = () => {
  return (
    <div>
      <h2>Product Widget</h2>
    </div>
  )
}

// The widget's configurations
export const config = defineWidgetConfig({
  zone: "product.details.after",
})

export default ProductWidget
```

This inserts a widget with the text “Product Widget” at the end of a product’s details page.

## Global Admin font

The Admin uses the locally hosted Vazirmatn variable font. Its source file is
`apps/backend/static/fonts/Vazirmatn-VariableFont_wght.ttf`, served by Medusa at
`/static/fonts/Vazirmatn-VariableFont_wght.ttf`. The URL is root relative, so it
works without a fixed hostname or an external font service.

`src/admin/plugins/persian-admin-font.ts` injects an `@font-face` rule into the
Admin HTML through the `admin.vite` hook in `medusa-config.ts`. The rule supports
weights 100–900. It applies the font to the page and its descendants, including
portals used for dialogs and dropdowns. `!important` overrides Medusa's own
font utilities; SVG icons and their descendants are excluded. This customization
does not set text direction or change translations.

### Development and production

Run `pnpm run backend:dev` from the repository root for development. Medusa
serves the font directly from `apps/backend/static`.

Run `pnpm --dir apps/backend run build` for a production backend build. Medusa
2.19 does not copy this font into its server output automatically, so the build
script copies it to
`apps/backend/.medusa/server/static/fonts/Vazirmatn-VariableFont_wght.ttf`.
The production server serves that copy at the same `/static/fonts/...` URL.

The production Docker image contains the built font and a second copy at
`/server/admin-fonts`. Docker Compose mounts a persistent volume at
`/server/static`, which can hide files baked into that directory. On server
startup, `develop.sh` copies the font from `/server/admin-fonts` into the mounted
directory. This also updates an existing volume after a new image is deployed.

### Browser check

1. Open `/app` and inspect **Network** in browser DevTools. Filter for
   `Vazirmatn-VariableFont_wght.ttf`. With the cache disabled, the request should
   return HTTP 200 from `/static/fonts/...`.
2. Inspect a heading, button, or input in **Elements → Computed**. Its
   `font-family` should be `Vazirmatn, sans-serif`.
3. Check that navigation and action icons still render. The current Medusa
   Admin uses SVG icons, which the font selector excludes.
