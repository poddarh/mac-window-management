const colors = {
  fg: "rgba(255,255,255,0.75)",
  dim: "rgba(255,255,255,0.5)",
  bg: "#1c1c1c",
  red: "#ff8700",
  accent: "#5fafaf",
  empty: "red",
  work: "#87afff",      // Blue for work profile
  personal: "#87d787"   // Green for personal profile
};

const typography = {
  fontSize: "18px",
  lineHeight: "24px",
  fontWeight: 500,
  fontFamily: "'SauceCodePro Nerd Font', monospace"
};

// Get profile color based on profile type
export const getProfileColor = (profileType) => {
  return profileType === "work" ? colors.work : colors.personal;
};

// Typography style mixin for container elements
export const typographyStyle = {
  fontFamily: typography.fontFamily,
  lineHeight: typography.lineHeight,
  fontSize: typography.fontSize,
  fontWeight: typography.fontWeight
};

export default {
  colors,
  ...typography
};
