import fs from "node:fs";
import toml from "toml";

export default {
  watch: ["../../packages/*/config.toml"],

  async load(watchedFiles: string[]) {
    return Object.fromEntries(
      watchedFiles.map((file) => {
        const config = toml.parse(fs.readFileSync(file, "utf-8"));
        return [config.name, config.version];
      })
    );
  },
};
