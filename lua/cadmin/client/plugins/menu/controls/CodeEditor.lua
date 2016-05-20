local PANEL = {}

function PANEL:Init ()
	self.Padding = 5
	
	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self:SetTitle ("Code Editor")
	self:SetIcon ("gui/silkicons/wrench")
	
	self.TextEntry = self:Create ("TextEntry")
	self.TextEntry:SetMultiline (true)
	self.TextEntry:SetText (string.format ("%c%c%c_%c%c%c", 224, 178, 160, 224, 178, 160))
	self.TextEntry:SetPos (self:GetPadding (), 24 + self:GetPadding ())
	self.TextEntry:SetSize (self:GetWide () - 2 * self:GetPadding (), 0.25 * self:GetTall () - 24 - 2 * self:GetPadding ())
	
	self.HTML = self:Create ("HTML")
	self.HTML:SetPos (self:GetPadding (), 24 + self:GetPadding () * 2 + self.TextEntry:GetTall ())
	self.HTML:SetSize (self:GetWide () - 2 * self:GetPadding (), self:GetTall () - 24 - 2 * self:GetPadding ())
	self.HTML:SetVisible (true)
	self.HTML:SetParent (self)
	self.HTML:SetHTML ([[
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
				<script type="text/javascript">
					var formInUse = false;
					function setFocus () {
						if (!formInUse) {
							document.getElementById ("text").focus ();
							document.body.style.margin = '0';
							document.body.style.padding = '0';
							document.body.style.border = '0';
							document.body.style.background = '#000000';
							document.body.style.overflow = 'hidden';
						}
					}
					function textChanged () {
						document.location = document.getElementById ("text").value;
					}
				</script>
				<style TYPE="text/css">
					body	{margin: 0px; padding: 0px;}
					input	{width: 490px;}
				</style>
			</head>
			<body onload="setFocus ()">
				<form action="http://trap" method="get">
					<input type="text" id="text" size="25" onchange="textChanged ()"></input>
				</form>
			</body>
		</html>]]
	)
	self.HTML.OpeningURL = function (html, url, target)
		Msg ("CHANGED: " .. url .. "\n")
		self.TextEntry:SetText (url)
		html:Stop ()
	end
end

CAdmin.GUI.Register ("CAdmin.CodeEditor", PANEL, "CFrame")