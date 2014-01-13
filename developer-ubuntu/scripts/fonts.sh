#!/bin/sh

CAT="/bin/cat"
FCCACHE="/usr/bin/fc-cache"
MKDIR="/bin/mkdir"
MV="/bin/mv"
SUDO="/usr/bin/sudo"
TAR="/bin/tar"
WGET="/usr/bin/wget"

${MKDIR} -p ~/.fonts
${WGET} 'http://www.gringod.com/wp-upload/MONACO.TTF'
${MV} MONACO.TTF ~/.fonts

${WGET} 'http://mengko616.googlepages.com/LiHeiProPC.ttf.tar.gz'
${TAR} xvfz LiHeiProPC.ttf.tar.gz
${MV} "LiHei ProPC.ttf" ~/.fonts

${CAT} > ~/.fonts.conf <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match target="pattern">
	<test qual="any" name="family">
	    <string>serif</string>
	</test>
	<edit name="family" mode="prepend" binding="strong">
	    <string>LiHei Pro</string>
	    <string>DejaVu Serif</string>
	    <string>Bitstream Vera Serif</string>
	    <string>AR PL UMing TW</string>
	    <string>AR PL UMing HK</string>
	    <string>AR PL ShanHeiSun Uni</string>
	    <string>AR PL New Sung</string>
	    <string>HYSong</string>
	    <string>WenQuanYi Bitmap Song</string>
	    <string>AR PL UKai TW</string>
	    <string>AR PL UKai HK</string>
	    <string>AR PL ZenKai Uni</string>
	</edit>
    </match> 
    <match target="pattern">
	<test qual="any" name="family">
	    <string>sans-serif</string>
	</test>
	<edit name="family" mode="prepend" binding="strong">
	    <string>LiHei Pro</string>
	    <string>DejaVu Sans</string>
	    <string>Bitstream Vera Sans</string>
	    <string>WenQuanYi Micro Hei</string>
	    <string>WenQuanYi Zen Hei</string>
	    <string>AR PL UMing TW</string>
	    <string>AR PL UMing HK</string>
	    <string>AR PL ShanHeiSun Uni</string>
	    <string>AR PL New Sung</string>
	    <string>HYSong</string>
	    <string>AR PL UKai TW</string>
	    <string>AR PL UKai HK</string>
	    <string>AR PL ZenKai Uni</string>
	</edit>
    </match> 
    <match target="pattern">
	<test qual="any" name="family">
	    <string>monospace</string>
	</test>
	<edit name="family" mode="prepend" binding="strong">
	    <string>LiHei Pro</string>
	    <string>DejaVu Sans Mono</string>
	    <string>Bitstream Vera Sans Mono</string>
	    <string>WenQuanYi Micro Hei Mono</string>
	    <string>WenQuanYi Zen Hei Mono</string>
	    <string>AR PL UMing TW</string>
	    <string>AR PL UMing HK</string>
	    <string>AR PL ShanHeiSun Uni</string>
	    <string>AR PL New Sung</string>
	    <string>HYSong</string>
	    <string>AR PL UKai TW</string>
	    <string>AR PL UKai HK</string>
	    <string>AR PL ZenKai Uni</string>
	</edit>
    </match> 
</fontconfig>
EOF

# fc-cache flush
${SUDO} ${FCCACHE} -f
