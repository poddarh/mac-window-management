import { run } from "uebersicht";

const wifiIcon = "";  // Font Awesome wifi (U+F1EB)

const refreshWifi = () => {
  // Clear the cache to force a fresh SSID lookup
  run("rm -f /tmp/nibar_wifi_ssid_cache");
};

const render = ({ output }) => {
  if (typeof output === "undefined") return null;
  const status = output.status;

  if (status === "inactive") {
    return (
      <div style={{ opacity: 0.5, textDecoration: "line-through" }}>
        {wifiIcon}
      </div>
    );
  }

  const ssid = output.ssid ? output.ssid.replace(/\s/g, '\xA0') : '';
  // Show just WiFi icon if SSID is empty or redacted
  if (!ssid || ssid === '<redacted>') {
    return (
      <div onClick={refreshWifi} style={{ cursor: "pointer" }}>
        {wifiIcon}
      </div>
    );
  }
  return (
    <div onClick={refreshWifi} style={{ cursor: "pointer" }}>
      {wifiIcon} {ssid}
    </div>
  );
};

export default render;
