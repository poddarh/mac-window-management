import * as Uebersicht from 'uebersicht'
import parse from "./lib/parse.jsx";
import Error from "./lib/Error.jsx";
import styles, { getProfileColor, typographyStyle } from "./lib/styles.jsx";

const { React } = Uebersicht;
const { useState, useEffect } = React;

const containerStyle = {
  padding: "0 8px",
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "8px",
  position: "fixed",
  overflow: "hidden",
  left: "50%",
  transform: "translateX(-50%)",
  bottom: "0px",
  ...typographyStyle,
  color: styles.colors.dim
};

const workspaceStyle = {
  cursor: "pointer",
  userSelect: "none"
};

const addButtonStyle = {
  cursor: "pointer",
  userSelect: "none",
  color: styles.colors.dim
};

const inputStyle = {
  background: "transparent",
  border: "none",
  borderBottom: `1px solid ${styles.colors.accent}`,
  color: styles.colors.fg,
  fontFamily: styles.fontFamily,
  fontSize: styles.fontSize,
  outline: "none",
  width: "80px",
  padding: "0"
};

const deleteButtonStyle = {
  cursor: "pointer",
  color: styles.colors.dim,
  marginLeft: "4px",
  fontSize: "12px"
};

const separatorStyle = {
  color: styles.colors.dim,
  margin: "0 4px"
};

// Workspace widget component
const WorkspaceSwitcher = ({ activeWorkspace, workspaces, workspaceProfiles }) => {
  const [mode, setMode] = useState('normal'); // 'normal', 'create', 'selectProfile', 'rename', 'delete'
  const [inputValue, setInputValue] = useState('');
  const [targetWorkspace, setTargetWorkspace] = useState('');
  const [pendingName, setPendingName] = useState(''); // Name waiting for profile selection

  // Get profile for a workspace
  const getProfile = (name) => {
    return workspaceProfiles[name] || "personal";
  };

  // Sort workspaces: work profiles first, then personal
  const sortedWorkspaces = [...workspaces].sort((a, b) => {
    const profileA = getProfile(a);
    const profileB = getProfile(b);
    if (profileA === profileB) {
      return a.localeCompare(b);
    }
    return profileA === "work" ? -1 : 1;
  });

  // Reset mode when activeWorkspace changes
  useEffect(() => {
    setMode('normal');
    setInputValue('');
    setTargetWorkspace('');
    setPendingName('');
  }, [activeWorkspace]);

  const switchToWorkspace = (name) => {
    if (mode !== 'normal') return;
    if (name !== activeWorkspace) {
      Uebersicht.run(`$HOME/.yabai/workspaces/manager.sh switch "${name}"`);
    }
  };

  const createWorkspace = (name, profile) => {
    if (name && name.trim()) {
      Uebersicht.run(`$HOME/.yabai/workspaces/manager.sh create "${name.trim()}" "${profile}"`);
    }
    setMode('normal');
    setInputValue('');
    setPendingName('');
  };

  const renameWorkspace = (oldName, newName) => {
    if (newName && newName.trim() && newName.trim() !== oldName) {
      Uebersicht.run(`$HOME/.yabai/workspaces/manager.sh rename "${oldName}" "${newName.trim()}"`);
    }
    setMode('normal');
    setInputValue('');
    setTargetWorkspace('');
  };

  const deleteWorkspace = (name) => {
    Uebersicht.run(`$HOME/.yabai/workspaces/manager.sh delete "${name}"`);
    setMode('normal');
    setTargetWorkspace('');
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      if (mode === 'create') {
        // Move to profile selection
        if (inputValue && inputValue.trim()) {
          setPendingName(inputValue.trim());
          setMode('selectProfile');
          setInputValue('');
        }
      } else if (mode === 'rename') {
        renameWorkspace(targetWorkspace, inputValue);
      }
    }
  };

  const handleDoubleClick = (e, name) => {
    e.stopPropagation();
    setMode('rename');
    setTargetWorkspace(name);
    setInputValue(name);
  };

  const handleRightClick = (e, name) => {
    e.preventDefault();
    setMode('delete');
    setTargetWorkspace(name);
  };

  const handleAddClick = (e) => {
    e.stopPropagation();
    if (mode === 'create' || mode === 'selectProfile') {
      // Clicking [+] again cancels create mode
      setMode('normal');
      setInputValue('');
      setPendingName('');
    } else {
      setMode('create');
      setInputValue('');
    }
  };

  // Render a single workspace
  const renderWorkspace = (name, isActive) => {
    const profile = getProfile(name);
    const profileColor = getProfileColor(profile);

    const style = {
      ...workspaceStyle,
      color: isActive ? profileColor : styles.colors.dim,
      fontWeight: isActive ? "700" : styles.fontWeight
    };

    // If in rename mode for this workspace
    if (mode === 'rename' && targetWorkspace === name) {
      return (
        <span key={name} style={{display: 'flex', alignItems: 'center'}}>
          <input
            type="text"
            style={{...inputStyle, borderBottomColor: profileColor}}
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          <span
            style={{...deleteButtonStyle, marginLeft: '4px'}}
            onClick={() => { setMode('normal'); setInputValue(''); setTargetWorkspace(''); }}
            title="Cancel"
          >
            [x]
          </span>
        </span>
      );
    }

    return (
      <span
        key={name}
        style={style}
        onClick={() => switchToWorkspace(name)}
        onDoubleClick={(e) => handleDoubleClick(e, name)}
        onContextMenu={(e) => handleRightClick(e, name)}
        title="Click: switch | Double-click: rename | Right-click: delete"
      >
        {isActive ? "[" : <span>&nbsp;</span>}
        {name}
        {isActive ? "]" : <span>&nbsp;</span>}
      </span>
    );
  };

  // Render delete confirmation
  if (mode === 'delete') {
    const profile = getProfile(targetWorkspace);
    const profileColor = getProfileColor(profile);
    return (
      <div style={containerStyle}>
        <span style={{color: styles.colors.dim}}>delete {targetWorkspace}?</span>
        <span
          style={{...workspaceStyle, color: profileColor, fontWeight: '700'}}
          onClick={() => deleteWorkspace(targetWorkspace)}
        >
          [yes]
        </span>
        <span
          style={{...workspaceStyle, color: styles.colors.dim}}
          onClick={() => { setMode('normal'); setTargetWorkspace(''); }}
        >
          [no]
        </span>
      </div>
    );
  }

  // Render profile selection
  if (mode === 'selectProfile') {
    return (
      <div style={containerStyle}>
        <span style={{color: styles.colors.dim}}>"{pendingName}" profile:</span>
        <span
          style={{...workspaceStyle, color: styles.colors.work, fontWeight: '700'}}
          onClick={() => createWorkspace(pendingName, 'work')}
        >
          [work]
        </span>
        <span
          style={{...workspaceStyle, color: styles.colors.personal, fontWeight: '700'}}
          onClick={() => createWorkspace(pendingName, 'personal')}
        >
          [personal]
        </span>
        <span
          style={addButtonStyle}
          onClick={handleAddClick}
          title="Cancel"
        >
          [x]
        </span>
      </div>
    );
  }

  // Render create input
  if (mode === 'create') {
    return (
      <div style={containerStyle}>
        {sortedWorkspaces.map((name, idx) => {
          const elements = [renderWorkspace(name, name === activeWorkspace)];
          // Add separator between work and personal groups
          if (idx < sortedWorkspaces.length - 1) {
            const currentProfile = getProfile(name);
            const nextProfile = getProfile(sortedWorkspaces[idx + 1]);
            if (currentProfile !== nextProfile) {
              elements.push(<span key={`sep-${idx}`} style={separatorStyle}>|</span>);
            }
          }
          return elements;
        })}
        <input
          type="text"
          style={inputStyle}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="new..."
          autoFocus
        />
        <span
          style={addButtonStyle}
          onClick={handleAddClick}
          title="Cancel"
        >
          [x]
        </span>
      </div>
    );
  }

  // Normal mode
  return (
    <div style={containerStyle}>
      {sortedWorkspaces.map((name, idx) => {
        const elements = [renderWorkspace(name, name === activeWorkspace)];
        // Add separator between work and personal groups
        if (idx < sortedWorkspaces.length - 1) {
          const currentProfile = getProfile(name);
          const nextProfile = getProfile(sortedWorkspaces[idx + 1]);
          if (currentProfile !== nextProfile) {
            elements.push(<span key={`sep-${idx}`} style={separatorStyle}>|</span>);
          }
        }
        return elements;
      })}
      <span
        style={addButtonStyle}
        onClick={handleAddClick}
        title="Create new workspace"
      >
        [+]
      </span>
    </div>
  );
};

export const refreshFrequency = false;
export const command = "$HOME/.yabai/workspaces/manager.sh query";

export const render = ({ output }) => {
  const data = parse(output);

  if (typeof data === "undefined") {
    return (
      <div style={containerStyle}>
        <Error msg="Error: unknown script output" side="center" />
      </div>
    );
  }

  const activeWorkspace = data.activeWorkspace || "default";
  const workspaces = data.workspaces || ["default"];
  const workspaceProfiles = data.workspaceProfiles || {};

  return (
    <WorkspaceSwitcher
      activeWorkspace={activeWorkspace}
      workspaces={workspaces}
      workspaceProfiles={workspaceProfiles}
    />
  );
};

export default null;
