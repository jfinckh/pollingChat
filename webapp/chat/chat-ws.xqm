module namespace chat = 'http://basex.org/modules/web-page';

import module namespace session = 'http://basex.org/modules/Session';
import module namespace sessions = 'http://basex.org/modules/Sessions';
import module namespace ws = 'http://basex.org/modules/ws';

(:~ Session chat id. :)
declare variable $chat:ID		  := 'chat';
(:~ WebSocket ID of the WebSocket instance :)
declare variable $chat:ws-ID   := 'ws-id';
(:~  Messages :)
declare variable $chat:messages := 'messages';

declare
  %rest:path('/chat/getChat')
  %rest:GET
  function chat:ws-getchat() as xs:string{
    let $json := chat:get-chat-info()
    return  json:serialize($json)
  };

declare
  %rest:path('/chat/sendMessage')
  %rest:POST
  %rest:form-param("message","{$message}", "(no message)")
  function chat:ws-sendmessage(
    $message as xs:string
  ) as empty-sequence(){
    let $json := parse-json($message)
    return chat:set-message($json?text, $json?to) 
  };
  
(:~ 
 : Processes a WebSocket message.
 : @param  $message  message
 :)
declare
  %ws:message('/chat', '{$message}')
function chat:ws-message(
  $message  as xs:string
) as empty-sequence() {
  let $json := parse-json($message)
  let $type := $json?type
  return if($type = 'message') then (
    chat:set-message($json?text, $json?to)
  ) else if($type = "ping") then(
    chat:ping()
  ) else error()
};


declare %private function chat:get-chat-info() as xs:string {
  json:serialize(
    map {
      'users': map {
        'userslist': array { sort(user:list()) },
        'active': array { distinct-values(
          sessions:ids() ! sessions:get(., $chat:ID)
        )} } ,
       'messages' : array{session:get($chat:messages)}
    
  }
)
};

(:~ 
 : Sends a message to all clients, or to the clients of a specific user.
 : @param  $text  text to be sent
 : @param  $to    receiver of a private message (optional)
 :)
declare %private function chat:set-message(
  $text  as xs:string,
  $to    as xs:string?
) as empty-sequence() {
  let $message := json:serialize(map {
    'type': 'message',
    'text': serialize($text),
    'from': session:get($chat:ID),
    'date': format-time(current-time(), '[H02]:[m02]:[s02]'),
    'private': boolean($to)
  })
  
    
  return if($to) then (
    for $id in sessions:ids()
    where sessions:get($id, $chat:ID) = $to
    let $msg := sessions:get($id, $chat:messages)
    let $new-msg := ($msg,$message)
    return sessions:set($id, $chat:messages, $new-msg)
  ) else (
    for $id in sessions:ids()
    let $msg := sessions:get($id, $chat:messages)
    let $new-msg := ($msg,$message)
    return sessions:set($id,$chat:messages,$new-msg)
  )
};

(:~
  : Answers with a pong to a ping-message
  :)
declare %private function chat:ping(){
  ws:send(json:serialize(map{
    'type': 'pong'
  }),ws:id())
};
