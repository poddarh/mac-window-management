const render = ({ output }) => {
  if (typeof output === "undefined") return null;
  const status = output.status;
  if (status === "inactive") return <div>􀙈</div>;

  const ssid = output.ssid ? output.ssid.replace(/\s/g, '\xA0') : '';
  // Show just WiFi icon if SSID is empty or redacted
  if (!ssid || ssid === '<redacted>') {
    return <div></div>;
  }
  return <div> {ssid}</div>;
};

export default render;
