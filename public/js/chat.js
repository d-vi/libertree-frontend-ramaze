function fetchChatMessage(chatMessage) {
  var messages = $('#chat-window .log[data-member-id="'+chatMessage.partnerMemberId+'"] .messages');
  $.get(
    '/chat/_message/' + chatMessage.id,
    function(html) {
      var o = $(html);
      o.appendTo(messages);
      var height = o.height();
      var animationDuration = height*5;
      o.hide().slideDown(animationDuration);

      messages.animate(
        { scrollTop: messages.scrollTop() + height + 30 },
        animationDuration
      );
    }
  );
}

function updateNumChatUnseen(n) {
  if( n == 0 ) {
    $('#num-chat-unseen').hide();
  } else {
    $('#num-chat-unseen').show();
  }
  $('#num-chat-unseen').html(n);
}

function updateNumChatUnseenForPartner(memberId, n) {
  var tab = $('#chat-window .tab[data-member-id="'+memberId+'"]');
  var indicator = tab.find('.num-chat-unseen');
  if( n == 0 ) {
    indicator.hide();
  } else {
    indicator.show();
  }
  indicator.html(n);
}

function markChatConversationSeen(memberId) {
  $.get(
    '/chat/seen/'+memberId,
    function(html) {
      updateNumChatUnseen(html);
      updateNumChatUnseenForPartner(memberId, 0);
    }
  );
}

function fetchChatConversationWith(memberId, andActivate) {
  if( $('#chat-window .tab[data-member-id="'+memberId+'"]').length ) {
    activateChatConversation(memberId);
    return false;
  }

  $.get(
    '/chat/_tab/'+memberId,
    function(html) {
      $(html).appendTo('#chat-window .tabs');
    }
  );
  $.get(
    '/chat/_log/'+memberId,
    function(html) {
      var o = $(html);
      o.appendTo('#chat-window .logs');
      o.find('.messages').scrollTop(999999);
      o.find('.textarea-chat').focus();
      if( andActivate ) {
        activateChatConversation(memberId);
      }
    }
  );
}

function activateChatConversation(memberId) {
  $('#chat-window .tab, #chat-window .log').removeClass('active');
  $('#chat-window .tab[data-member-id="'+memberId+'"]').addClass('active');
  $('#chat-window .log[data-member-id="'+memberId+'"]').addClass('active');
  $('#chat-window .log.active .textarea-chat').focus();
  syncChatUIDimensions()
  $('#chat-window .log.active .messages').scrollTop(999999);
}

function receiveChatMessage(data) {
  var tab = $('#chat-window .tab[data-member-id="'+data.partnerMemberId+'"]');

  if( tab.length == 0 ) {
    fetchChatConversationWith(data.partnerMemberId, false);
  }

  if( $('#chat-window').is(':visible') && tab.hasClass('active') ) {
    markChatConversationSeen(data.partnerMemberId);
  } else {
    updateNumChatUnseen(data.numUnseen);
    updateNumChatUnseenForPartner(data.partnerMemberId, data.numUnseenForPartner);
  }

  fetchChatMessage(data);
}

function syncChatUIDimensions() {
  $('#chat-window .log.active .messages').height(
    $('#chat-window').height() - 157
  );
  $('#chat_new_partner_chzn').width(
    $('#chat-window').width() - 10
  );
}

function rememberChatDimensions() {
  $.get(
    '/chat/remember_dimensions/'
    + $('#chat-window').css('top')
    + '/'+$('#chat-window').css('left')
    + '/'+$('#chat-window').css('width')
    + '/'+$('#chat-window').css('height')
  );
}

/* ---------------------------------------------------------------------------- */

$(document).ready( function() {
  $('#menu-chat').click( function() {
    if( $('#chat-window').is(':visible') ) {
      hideWindows();
      return false;
    }

    hideWindows();
    $('#chat-window').empty();
    addSpinner('#chat-window');
    $('#chat-window')
      .show()
      .load(
        '/chat/_index',
        function(html) {
          checkForSessionDeath(html);
          removeSpinner('#chat-window');
          $('#chat-window').hide();
          var o = $(html);
          markChatConversationSeen( o.find('.log.active').data('member-id') );

          $('#chat-window')
            .resizable( {
              minHeight: 170,
              resize: function(event, ui) {
                syncChatUIDimensions();
              },
              stop: function(event, ui) {
                rememberChatDimensions();
              }
            } )
          ;

          $('select#chat-new-partner').chosen().change( function() {
            var memberId = $('select#chat-new-partner').val();
            fetchChatConversationWith(memberId, true);
            $('select#chat-new-partner').val('0');
            $('select#chat-new-partner').trigger("liszt:updated");
            return false;
          } );

          syncChatUIDimensions();
          $('#chat-window').show();
          $('#chat-window .log .messages').scrollTop(999999);
          $('#chat-window .log.active .textarea-chat').focus();
        }
      )
    ;
    return false;
  } );

  $('#chat-window .tab').live( 'click', function() {
    var memberId = $(this).data('member-id');
    activateChatConversation(memberId);
    markChatConversationSeen(memberId);
  } );

  $('#chat-window .textarea-chat').live( 'keydown', function(event) {
    if( event.keyCode != 13 ) {
      return;
    }

    var textarea = $(this);

    textarea.attr('disabled', 'disabled');
    clearInterval(timerSaveTextAreas);
    var memberId = $(this).closest('.log').data('member-id');

    $.post(
      '/chat/create',
      {
        to_member_id: memberId,
        text: textarea.val()
      },
      function(response) {
        var h = $.parseJSON(response);
        if( h.success ) {
          textarea.val('');
        } else {
          alert('Failed to send chat message.');
        }
        textarea.removeAttr('disabled');
      }
    );
  } );

  $('#chat-window .tab .close').live( 'click', function() {
    var tab = $(this).closest('.tab');
    var memberId = tab.data('member-id');
    var tabToActivate = tab.next();
    if( tabToActivate.length == 0 ) {
      tabToActivate = tab.prev();
    }
    $('#chat-window .tab[data-member-id="'+memberId+'"]').remove();
    $('#chat-window .log[data-member-id="'+memberId+'"]').remove();
    $.get('/chat/closed/'+memberId);
    if( $('#chat-window .tab.active').length == 0 && tabToActivate.length ) {
      activateChatConversation( tabToActivate.data('member-id') );
    }
    return false;
  } );

  $('#chat-window').draggable( {
    handle: '.header',
    stop: function(event, ui) {
      rememberChatDimensions();
    }
  } );


  $('#chat-window').css( {
    top: chat_top,
    left: chat_left,
    width: chat_width,
    height: chat_height
  } );
} );
