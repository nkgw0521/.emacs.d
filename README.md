# .emacs.d
## apt-get install
- fonts-migmix
- cmigemo
- global
- exuberant-ctags
    ~~~
    $ sudo apt install exuberant-ctags
    ~~~
  - インストール後の状態
    update-alternatives: /usr/bin/ctags (ctags) を提供するために自動モードで /usr/bin/ctags-exuberant を使います
    ~~~
    $ ls -la /usr/bin/ctags 
    lrwxrwxrwx 1 root root 23  9月 24  2019 /usr/bin/ctags -> /etc/alternatives/ctags 
    $ ls -la /etc/alternatives/ctags 
    lrwxrwxrwx 1 root root 24  7月 14 08:58 /etc/alternatives/ctags -> /usr/bin/ctags-exuberant
    ~~~
    
## package  
- list-packages
    - migemo
    - ggtags
    - color-moccur
    - moccur-edit
    - hiwin
    - package-utils
    - color-theme
    - color-theme-wombat
