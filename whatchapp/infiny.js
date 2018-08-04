// var jq = document.createElement('script');
// jq.src = "https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js";
// document.getElementsByTagName('head')[0].appendChild(jq);

function confirmLoginOnThisDevice() {
    var button = $("#app > div > div > div > div > div > div > div._3QNwO > div._1WZqU.PNlAR");
    var buttonExists = button.length != 0;
    if (buttonExists) {
        button.click();
    }
    return buttonExists;
}

function getQRCodeBase64() {
    return $("#app > div > div > div._2NbD3 > div > div.XSdna > div > img").attr("src");
}

function getChatDivs() {
    return $("#pane-side > div > div > div > div > div > div").sort(
                                                                    function(a, b) {
                                                                    var aHeight = $(a).offset().top;
                                                                    var bHeight = $(b).offset().top;
                                                                    return aHeight - bHeight;
                                                                    }
                                                                    );
}

function chatName(chatDiv) {
    var groupChatName = $(chatDiv).find("._25Ooe > ._1wjpf").attr("title");
    var contactChatName = $(chatDiv).find("._25Ooe > ._3TEwt > ._1wjpf").attr("title");
    if (typeof groupChatName != 'undefined') {return groupChatName;}
    else return contactChatName;
}

function chatMessage(chatDiv) {
    var sender = $(chatDiv).find("div._3j7s9 > div._1AwDx > div._itDl > span > span._1bX-5 > span").text();
    var text = $(chatDiv).find("div._3j7s9 > div._1AwDx > div._itDl > span").attr("title");
    if (sender === "" || sender === undefined) {
        return text;
    } else {
        return sender + ": " + text;
    }
}

function chatImageURL(chatDiv) {
    return $(chatDiv).find("div.dIyEr > div > img").attr("src");
}

function chatDate(chatDiv) {
    return $(chatDiv).find("div._3j7s9 > div._2FBdJ > div._3Bxar > span").text();
}

function getAllChats() {
    return $.map( getChatDivs(), function( val, i ) {
                 blobToBase64(chatImageURL(val));
                 return  {
                 message: chatMessage(val),
                 name: chatName(val),
                 date: chatDate(val),
                 imgURL: chatImageURL(val),
                 };
                 });
}

function getAllChatsAsJson() {
    return JSON.stringify(getAllChats());
}

function triggerMouseEvent(node, eventType) {
    var event = document.createEvent('MouseEvents');
    event.initEvent(eventType, true, true);
    node.dispatchEvent(event);
}

function selectChat(chatDiv){
    triggerMouseEvent(chatDiv, "mousedown");
}

function selectChatWithName(name) {
    $.each( getChatDivs(), function( index, ele ) {
           if (chatName(ele) === name) {
           selectChat(ele);
           }
           });
}

function getAllCurrentlyShowingMessagesAsJson() {
    return JSON.stringify(getAllCurrentlyShowingMessages());
}

function sendMessage(text, chatname){
    var name = $("#main > header > div._1WBXd > div._2EbF- > div > span").attr("title");
    if (name != chatname) return;
    
    $("#main > footer > div._3pkkz > div._1Plpp > div > div._2S1VP.copyable-text.selectable-text").text(text);
    var input = document.querySelector("#main > footer > div._3pkkz > div._1Plpp > div > div._2S1VP.copyable-text.selectable-text");
    input.dispatchEvent(new Event('input', {bubbles: true}));
    var button = document.querySelector('#main > footer > div._3pkkz > div > button');
    button.click();
}

function messageIsOwn(leaf) {
    return $(leaf).find("div.message-out").length > 0;
}

function filterMessageFromLeaf(leaf) {
    var message = "";
    if ($(leaf).is('em') || ($(leaf).attr('alt') != "" && $(leaf).attr('alt') != undefined)) {
        // If there are nested ems (system symbols) or imgs (smileys), go one
        // layer up and add all texts and alts to one string
        $.each( $(leaf).parent().contents(), function( index, ele ) {
               var alt = $(ele).attr("alt");
               if (alt !== undefined) {
               message += $(ele).attr("alt");
               }
               message += $(ele).text();
               });
    } else {
        // Otherwise just use the text of the element
        message = $(leaf).text();
    }
    return message;
}

// Return all children of given message div
function childrenOf(div) {
    return $(div).find('*').map(function() {
                                message = filterMessageFromLeaf(this);
                                if ($(this).children().length === 0 && message != "") {
                                return {
                                message: message,
                                color: rgba2hex($(this).css('color')),
                                alpha: rgba2alpha($(this).css('color')),
                                size: $(this).css('font-size'),
                                };
                                } else if ($(this).attr('src') != "" && $(this).attr('src') != undefined) {
                                blobToBase64($(this).attr('src'));
                                return {
                                src: $(this).attr('src'),
                                };
                                }
                                }).toArray();
}


// Return all visible messages in JSON format
function allVisibleMessages() {
    var allMessageDivs = $('#main > div._3zJZ2 > div > div > div._9tCEa > div');
    return JSON.stringify(allMessageDivs.map( function() {
                                             return {
                                             'own': messageIsOwn(this),
                                             'children': childrenOf(this),
                                             };
                                             }).toArray());
}

function trim (str) {
    return str.replace(/^\s+|\s+$/gm,'');
}

//Function to convert hex format to a rgb color
function rgba2hex(rgb){
    if (rgb === undefined) return "#000000";
    rgb = rgb.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i);
                    return  (rgb && rgb.length === 4) ? "#" +
                    ("0" + parseInt(rgb[1],10).toString(16)).slice(-2) +
                    ("0" + parseInt(rgb[2],10).toString(16)).slice(-2) +
                    ("0" + parseInt(rgb[3],10).toString(16)).slice(-2) : '';
                    }
                    
                    function rgba2alpha(rgb) {
                    var match = rgb.match(/^rgba\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d*(?:\.\d+)?)\)$/);
                    return match ? Number(match[4]) : 1;
                    }
                    
                    function blobToBase64(blobUrl) {
                    var request = new XMLHttpRequest();
                    request.open('GET', blobUrl, true);
                    request.responseType = 'blob';
                    request.onload = function() {
                    var reader = new FileReader();
                    reader.readAsDataURL(request.response);
                    reader.onload =  function(e) {
                    blobCallback(blobUrl, e.target.result);
                    };
                    };
                    request.send();
                    }
                    
                    function blobCallback(blobUrl, base64) {
                    webkit.messageHandlers.blobToBase64Callback.postMessage(JSON.stringify({
                                                                                           blobUrl: blobUrl,
                                                                                           base64: base64,
                                                                                           }));
                    }
                    
                    function sleep(ms) {
                    return new Promise(resolve => setTimeout(resolve, ms));
                    }
                    
                    MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
                    var domChangeQueued = false;
                    
                    var observer = new MutationObserver(async function(mutations, observer) {
                                                        var mutatedByJQuery = false;
                                                        mutations.forEach(function(mutation) {
                                                                          if (mutation.attributeName == "id") {
                                                                          mutatedByJQuery = true;
                                                                          }
                                                                          });
                                                        if (!domChangeQueued && !mutatedByJQuery) {
                                                        domChangeQueued = true;
                                                        await sleep(1000);
                                                        domCallback();
                                                        domChangeQueued = false;
                                                        }
                                                        });
                    
                    observer.observe(document.body, {
                                     subtree: true,
                                     attributes: true,
                                     attributeOldValue: true,
                                     });
                    
                    function domCallback() {
                    webkit.messageHandlers.domChangedCallback.postMessage({});
                    }
