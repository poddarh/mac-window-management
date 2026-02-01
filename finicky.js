// Finicky configuration
// Routes URLs to Chrome profiles based on active yabai workspace

const WORK_PROFILE = {
  name: "Google Chrome",
  profile: "Default"
};

const PERSONAL_PROFILE = {
  name: "Google Chrome",
  profile: "Profile 10"
};

module.exports = {
  defaultBrowser: "Google Chrome",

  handlers: [
    // Route based on active workspace's profile type
    {
      match: () => true,
      browser: function() {
        // Get profile type for active workspace (work or personal)
        // Uses ~/.yabai symlink (see install.sh)
        const homeDir = finicky.run("/bin/sh", ["-c", "echo $HOME"]).trim();
        const result = finicky.run(homeDir + "/.yabai/workspaces.sh", ["profile"]);
        const profileType = result.trim();

        // Route to appropriate Chrome profile
        if (profileType === "work") {
          return WORK_PROFILE;
        } else {
          return PERSONAL_PROFILE;
        }
      }
    }
  ]
};
