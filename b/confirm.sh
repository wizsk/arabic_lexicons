if [ -d "$bd" ]; then
  if [ "$1" = "yy" ]; then
    p="y"
  elif [ "$1" = "nn" ]; then
    p="n"
  else
    printf "Delete $bd [y/N] "
    read -r p
  fi

  if [ "$p" = "y" ] || [ "$p" = "Y" ]; then
    printf "rm $bd\n\n"
    rm -r "$bd"
  else
    printf "Keeping $bd\n\n"
  fi
fi

if [ ! -d "$bd" ];then
  mkdir "$bd"
fi
