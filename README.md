# DOTFILES
自用配置文件(for macos only)

## !!!!!!!!!!
务必备份原有配置

## 基础环境配置

### Macvim 专属
```bash
# 字体，source code pro with icon
brew tap homebrew/cask-fonts && brew cask install font-saucecodepro-nerd-font
# ctags, use universal-ctags
brew uninstall --ignore-dependencies ctags 
brew install --with-jansson --HEAD universal-ctags/universal-ctags/universal-ctags
# gtags
brew install global
# macvim
brew install macvim
```

## 安装
```bash
./install.sh
```

## UNINSTALL
```bash
./uninstall.sh
```

