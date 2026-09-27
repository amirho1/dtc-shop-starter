import { defineWidgetConfig } from "@medusajs/admin-sdk";

const GlobalFontWidget = () => {
  return <style href="./fonts.css" />;
};

export const config = defineWidgetConfig({
  zone: "topbar",
});

export default GlobalFontWidget;
