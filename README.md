# SpringBoot-start.nvim

Neovim plugin for initializing spring boot projects.

## Getting started

Although the environment for writing Java code in Intellij idea is already quite comprehensive, I prefer to do most of the work within the terminal or Neovim. After configuring jdtls, it was discovered that initializing the SpringBoot project may also occur in neovim, so this plugin was written. Because I am not a professional Java programmer, I have currently implemented a small portion of the functionality. More features may be listed in my TODO schedule.

## ✨ Features

- Generate a Maven/Gradle Spring Boot Project
- Customize configurations for a new project(use getpar function: language, java version, group id, artifact id, boot version and dependencies)
- Search for dependencies
- Quick generate project with last settings


## ⚡️ Requirements

- [neovim >= 0.8](https://github.com/neovim/neovim/releases/tag/v0.8.0)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) is required
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is required
- command `curl` is required

## 📦 Installation

Install it with your preferred package manager:

> Note: Because the basic information for creating a springboot project may be obtained from the internet when starting the menu for the first time, it may get stuck, but after that, the information will be read from the cache file. Unless the cache is deleted.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'niT-Tin/springboot-start.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'MunifTanjim/nui.nvim',
    },
    config = function()
        require('springboot-start').setup({
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        })
    end
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'niT-Tin/springboot-start.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'MunifTanjim/nui.nvim',
    },
    config = function()
        require('springboot-start').setup({
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        })
    end
}
```

## ⚙️  Configuration

> Note: Currently, there are not many optional configurations available. The following configuration is a partial UI configuration for the input box when inputting relevant parameters.

For more default configurations such as the Telescope option, confirm input, and other shortcut keys, please refer to [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim#default-mappings) default configuration.

For text input box, pressing `<CR>` to submit inputs and `<C-c>` close the window.
For more information, please refer to the [nui.nvim](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/input) documentation.

**SpringBoot-start**  comes with the following defaults:

```lua
{
  input = {
    position = {
      row = 20, -- One fifth of the current window row count
      col = 20, -- Two fifths of the current window columns
    },
    size = {
      width = 25,
      height = 10,
    },
    border = {
      style = "single",
      text = {
        top = "[Dep]", -- The text you want to place at the top of the input box
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
    prompt = "> "
  },
}
```

## 🚀 Usage

### Commands

Please use `:SpringBootStartMenu` for the first startup, which will create some basic data cache files.

- `:SpringBootStartMenu`
    Summary display of the plugin's functions.

- `:SpringBootGetDep`
    Select the dependencies that need to be added when creating a springboot project.

- `:SpringBootGetProjectType`
    Choose the type of project to create when creating a springboot project.

- `:SpringBootGetParam`
    Modify or select the configuration information of the spring boot project when creating it.(Use default information if not modified)

- `:SpringBootChoseDir`
    Enter the location where the project is stored.

- `:SpringBootShowDep`
    Display the selected dependency items.                        

- `:SpringBootShowProjectType`
    Display the selected project types.

- `:SpringBootShowParam`
    Display Project Configuration.

- `:SpringBootShowSelected`
    Display all project options (type, configuration, creation location, dependencies).

- `:SpringBootCreate`
    Create project(also creating the cache file).
    
- `:SpringBootRemoveCache`
    Remove all cache files.

- `:SpringBootUpdateCache`
    Update all cache files with current selections. 
    
- `:SpringBootShowLast`
    Display all options and configurations for the previous project creation.

- `:SpringBootCreateLast`
    Create a project based on the previous configuration and options.

- `:SpringBootGetLast`
    Obtain the previous configuration and options for easy modification and re creation of the project.

- `:SpringBootDeleteDep`
    Display the currently selected dependencies and provide deletion function.

- `:SpringBootCacheDir`
    Display cache files location

### API

The Lua API corresponds to the Vim command functionality one by one.

```lua
-- Summary display of the plugin's functions.
require('springboot-start').menu()
```

```lua
-- Select the dependencies that need to be added when creating a springboot project.
require('springboot-start').getdep()
```

```lua
-- Choose the type of project to create when creating a springboot project.
require('springboot-start').gettype()
```

```lua
-- Modify or select the configuration information of the spring boot project when creating it.(Use default information if not modified)
require('springboot-start').getpara()
```

```lua
-- Enter the location where the project is stored.
require('springboot-start').chose_dir()
```

```lua
-- Display the selected dependency items.                        
require('springboot-start').show_dep()
```

```lua
-- Display the selected project types.
require('springboot-start').show_rel()
```

```lua
-- Display Project Configuration.
require('springboot-start').show_para()
```

```lua
-- Display all project options (type, configuration, creation location, dependencies).
require('springboot-start').show_selected()
```

```lua
-- Create project(also creating the cache file).
require('springboot-start').create_project()
```

```lua
-- Remove all cache files.
require('springboot-start').remove_cache()
```

```lua
-- Update all cache files.
require('springboot-start').update_cache()
```

```lua
-- Display all options and configurations for the previous project creation.
require('springboot-start').show_last_selected()
```

```lua
-- Create a project based on the previous configuration and options.
require('springboot-start').create_last()
```

```lua
-- Obtain the previous configuration and options for easy modification and re creation of the project.
require('springboot-start').get_last()
```

```lua
-- Display the currently selected dependencies and provide deletion function.
require('springboot-start').delete_dep()
```

```lua
-- Display cache files location
require('springboot-start').cache_dir()
```
