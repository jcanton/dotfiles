#!/bin/bash

# 1
i3-msg 'workspace 1:loc; exec chromium'
sleep 5
i3-msg 'workspace 1:loc; exec obsidian'
sleep 5
#i3-msg 'workspace 1:loc; exec chromium --profile-directory=Default --app-id=pjibgclleladliembfgfagdaldikeohf'
i3-msg 'workspace 1:loc; exec i3-sensible-terminal'
#sleep 5

# # 2
# i3-msg 'workspace 2:code; exec i3-sensible-terminal'
# sleep 5
# i3-msg 'workspace 2:code; exec code'
# sleep 5
