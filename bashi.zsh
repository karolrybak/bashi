#!/bin/zsh

(( ! $+commands[jq] )) && echo "jq must be installed https://github.com/jqlang/jq" && return

if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
else 
  OS=$(uname -s)
fi

API_URL="https://api.openai.com/v1/chat/completions"
BASHI_PROMPT="User os is $OS. Write a one line bash script to complete task. Use modern cli tools like ripgrep, fzf, rsync DO NOT use formatting DO NOT use markdown. Return single line executable script"

bashi(){
  setopt extendedglob

  [ -n "$BUFFER" ] || { return }
  USER_QUERY=$(echo $BUFFER | jq -Ra)
  PAYLOAD=$(cat <<EOF
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "$BASHI_PROMPT"
    },
    {
      "role": "user",
      "content": $USER_QUERY
    }
  ]
}
EOF
)
    response=$(curl -s $API_URL \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "$PAYLOAD" | jq -r '.choices[0].message.content')
    BUFFER="$response"
    zle end-of-line
    zle reset-prompt
    return $ret
}

autoload -U bashi
zle -N bashi
bindkey "^o" bashi