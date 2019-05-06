<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="False" EnableViewState="False" EnableViewStateMac="False" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
<title>Header Dump</title>
</head>
<body>
<form id="formHeaderDump" runat="server">
<div id="divHeaderDump">
<asp:Literal ID="litrlHeaderDump" runat="server" />
</div>
</form>
</body>
</html>
<script runat="server">
void Page_Load(object sender, EventArgs e)
{
Response.Cache.SetCacheability(HttpCacheability.NoCache);

foreach (string strKey in Request.Headers.AllKeys)
litrlHeaderDump.Text += strKey + " = " + Request.Headers[strKey] + "<br />\n";
}
</script>