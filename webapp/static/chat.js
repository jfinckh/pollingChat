var to = "";

function processMessage(response) {
  var json = JSON.parse(JSON.parse(response));
  document.getElementById("messages").innerHTML = "";
  
  json.messages.forEach(
    function(msg) {
      var jsonmsg = JSON.parse(msg)
      var info = jsonmsg.from + ", " + jsonmsg.date;
      if(jsonmsg.private) info += " (private message)";
      var message = "<div>" + jsonmsg.text + "</div><div class='footnote'>" + info + "</div>";
      var msgelement = document.getElementById("messages");
      msgelement.innerHTML = message + msgelement.innerHTML;
    }
  );
  var users = "";
  json.users.userslist.forEach(function(user) {
      href = json.users.active.indexOf(user) != -1 ? "<b>" + user + "</b>" : user;
      users += "<a href='#' onclick=\"privateMsg('"+
        user.replace("'", "\\'") + "', event);\">" + href + "</a><br>";
    });
    document.getElementById("users").innerHTML = users;
};

// helper functions
function privateMsg(user, event) {
  to = user;
  var placeholder = "Private message to " + user + " (press ESC to cancel)…";
  var input = document.getElementById("input");
  input.placeholder = placeholder;
  input.focus();
  resetInput()
  event.preventDefault();
};

function resetPrivateMsg() {
  to = "";
  var placeholder = "Message to all users…";
  document.getElementById("input").placeholder = placeholder;
};

function resetInput() {
  document.getElementById("input").value = "";
};

function keyDown(event) {
  if(event.keyCode === 13) { // enter
    event.preventDefault();
    var message = document.getElementById("input").value;
    if(message) {
      sendMsg("message", message, to);
      resetInput()
    }
  } else if(event.keyCode === 27) { // escape
    resetPrivateMsg();
  }
};

function sendMsg(type, message, to) {
  console.log("called sendmsg");
  var xhttp = new XMLHttpRequest();
  xhttp.open("POST", "chat/sendMessage", true);
  var formData = new FormData();
  formData.append("message", JSON.stringify({ "type": type, "text": message, "to": to }))
  xhttp.send(formData);  
};

function poll() {
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      processMessage(this.responseText);
      setTimeout(poll,3000);
    }
  };
  xhttp.open("GET", "chat/getChat", true);
  xhttp.send();  
}

poll();