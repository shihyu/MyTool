<%@ page import = "$packagename$.$safeitemname$" %>

<jsp:useBean id="$safeitemname$Id" class="$packagename$.$safeitemname$" scope="session"/>
<jsp:setProperty name="$safeitemname$Id" property="name" param="name"/>

<HTML>
	<HEAD>
		<TITLE>$packagename$.$safeitemname$ Test</TITLE>
		<META NAME="Generator" CONTENT="SlickEdit v11">
		<META NAME="Author" CONTENT="$username$">
		<META NAME="Keywords" CONTENT="">
		<META NAME="Description" CONTENT="">
	</HEAD>
	<BODY>
		<FONT SIZE=3>
			This is a test of the $safeitemname$ bean...
			<BR><BR>
			Name = <%= $safeitemname$Id.getName() %>
			<BR><BR>
			<FORM METHOD=get>
				Enter a new name:<br>
				<INPUT TYPE=text NAME=name>
				<INPUT TYPE=submit VALUE="Submit">
			</FORM>
		</FONT>
	</BODY>
</HTML>


