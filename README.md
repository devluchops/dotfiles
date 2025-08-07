# 🚀 Dotfiles - DevLuchOps

Configuración modular y moderna para zsh con herramientas de productividad.

## � Instalación

```bash
cd ~/Git/dotfiles
chmod +x install.sh
./install.sh
```

El script automáticamente:
- ✅ Hace backup de tu configuración actual
- ✅ Instala plugins de Oh My Zsh (autosuggestions, syntax-highlighting)
- ✅ Copia configuración modular a `~/.config/zsh/`
- ✅ Configura `.env.local` para variables sensibles

## 🛠️ Incluye

**Funciones útiles:**
- `git_config_lva` / `git_config_work` - Cambiar perfiles Git
- `aws_sso` / `aws_sts` - Utilidades AWS mejoradas
- `myip` / `localip` - Ver IPs pública/local
- `mkcd`, `extract`, `weather`, `genpass` - Utilidades varias

**Aliases modernos:**
- Git: `gs`, `ga`, `gc`, `gp`, `gl`
- Docker: `d`, `dc`, `dps`
- Kubernetes: `k`, `kgp`, `kgs`
- Navegación: `ll`, `..`, `...`

## ⚙️ Personalización

- **Funciones**: Edita `.config/zsh/functions.zsh`
- **Aliases**: Edita `.config/zsh/aliases.zsh`
- **Variables**: Edita `.config/zsh/exports.zsh`
- **SSH**: Agrega tu config en `.ssh/config`
- **Secrets**: Usa `.env.local` para tokens/API keys

## 🔄 Actualización

```bash
cd ~/Git/dotfiles
git pull
cp .config/zsh/* ~/.config/zsh/
source ~/.zshrc
```

## � Herramientas recomendadas

```bash
brew install bat exa fd ripgrep fzf htop jq
```

---

**Simple, modular y productivo.** 🎉
