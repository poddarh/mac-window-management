import styles from "./styles.jsx";
import * as Uebersicht from 'uebersicht'

const containerStyle = {
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "8px"
};

const desktopStyle = {
  // width: '4ch',
};

const workspaceLabelStyle = {
  fontWeight: "700",
  marginRight: "4px",
  cursor: "pointer",
  userSelect: "none"
};

// Note that this can change at any time
const getCurrentDisplayId = (displays) => {
  let displayIndex = window.location.pathname.split('/')[1];
  let display = displays.filter(display => display.id == displayIndex)[0];
  return display.index;
}

// Get the color for a profile type
const getProfileColor = (profileType) => {
  return profileType === "work" ? styles.colors.work : styles.colors.personal;
};

// Check if a space belongs to the active workspace or is a profile-shared space
const isSpaceVisible = (label, activeWorkspace, profileType) => {
  if (!label || label === "") {
    // Unlabeled spaces are visible
    return true;
  }

  // Profile-shared spaces (7-10): {profileType}_07 through {profileType}_10
  const profilePattern = new RegExp(`^${profileType}_0[7-9]$`);
  if (profilePattern.test(label) || label === `${profileType}_10`) {
    return true;
  }

  // Workspace-specific spaces (activeWorkspace_01 through activeWorkspace_06)
  const workspacePattern = new RegExp(`^${activeWorkspace}_0[1-6]$`);
  if (workspacePattern.test(label)) {
    return true;
  }

  return false;
};

// Get display number for a space label
const getDisplayNumber = (label, activeWorkspace, profileType) => {
  if (!label || label === "") {
    return label;
  }

  // Profile-shared spaces: {profileType}_07 -> 7, {profileType}_10 -> 10
  const profilePattern = new RegExp(`^${profileType}_0([7-9])$`);
  const profileMatch = label.match(profilePattern);
  if (profileMatch) {
    return parseInt(profileMatch[1]);
  }
  if (label === `${profileType}_10`) {
    return 10;
  }

  // Workspace-specific spaces: {workspace}_01 -> 1
  const workspacePattern = new RegExp(`^${activeWorkspace}_0([1-6])$`);
  const match = label.match(workspacePattern);
  if (match) {
    return parseInt(match[1]);
  }

  return label;
};

const renderSpace = (index, label, focused, visible, windows, activeWorkspace, profileType) => {
  let contentStyle = JSON.parse(JSON.stringify(desktopStyle));

  let hasWindows = windows.length > 0;

  let name = getDisplayNumber(label, activeWorkspace, profileType);
  if (name === label || name === "" || name === undefined) {
    // Fallback for unlabeled or unrecognized labels
    name = "i" + index;
  }

  const profileColor = getProfileColor(profileType);

  if (focused) {
    contentStyle.color = profileColor;
    contentStyle.fontWeight = "700";
  } else if (visible) {
    contentStyle.color = styles.colors.fg;
  } else if (windows.length == 0) {
    contentStyle.color = styles.colors.empty;
  }
  return (
    <div style={contentStyle}
      onClick={() => {
        Uebersicht.run(`/opt/homebrew/bin/yabai -m space --focus ${index}`);
      }}
    >
      {focused ? "[" : <span>&nbsp;</span>}
      {name}
      {focused ? "]" : <span>&nbsp;</span>}
    </div>
  );
};

const render = ({ output, displays, activeWorkspace, profileType }) => {
  if (typeof output === "undefined") return null;
  const displayId = getCurrentDisplayId(displays);

  // Filter to current display
  let filteredSpaces = output.filter(space => space.display == displayId);

  // Filter by active workspace and profile type
  filteredSpaces = filteredSpaces.filter(space =>
    isSpaceVisible(space.label, activeWorkspace, profileType)
  );

  // Sort spaces: workspace-specific (1-6) first, then profile-shared (7-10)
  filteredSpaces = filteredSpaces.sort((a, b) => {
    const aNum = getDisplayNumber(a.label, activeWorkspace, profileType);
    const bNum = getDisplayNumber(b.label, activeWorkspace, profileType);
    if (typeof aNum === 'number' && typeof bNum === 'number') {
      return aNum - bNum;
    }
    return String(a.label).localeCompare(String(b.label));
  });

  let allWindows = filteredSpaces.reduce((agg, space) => agg.concat(space.windows), []);

  let windowsToCount = allWindows.reduce((agg, window) => {
    let windowsOnScreen = agg.hasOwnProperty(window) ? agg[window] : 0;
    agg[window] = windowsOnScreen + 1;
    return agg;
  }, {});

  let windowsOnAllSpaces = Object.keys(windowsToCount)
                                 .filter(window => windowsToCount[window] == filteredSpaces.length)
                                 .map(windowStr => parseInt(windowStr));

  filteredSpaces = filteredSpaces.map(space => {
    space.windows = space.windows.filter(window => !windowsOnAllSpaces.includes(window));
    return space;
  });

  filteredSpaces = filteredSpaces.filter(space => space.windows.length > 0 || space["is-visible"]);

  const spaces = [];

  // Add workspace label at the start (clickable to cycle workspaces)
  const profileColor = getProfileColor(profileType);
  spaces.push(
    <div
      key="workspace-label"
      style={{...workspaceLabelStyle, color: profileColor}}
      onClick={() => {
        Uebersicht.run(`$HOME/.yabai/workspaces.sh cycle`);
      }}
      title="Click to cycle workspaces"
    >
      {activeWorkspace}
    </div>
  );

  filteredSpaces.forEach(function (space) {
    spaces.push(renderSpace(space.index, space.label, space["has-focus"], space["is-visible"], space.windows, activeWorkspace, profileType));
  });

  return (
    <div style={containerStyle}>
      {spaces}
    </div>
  );
};

export default render;
