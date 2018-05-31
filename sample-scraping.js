<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script>
var nodes = $('#match-commentary-1-tab-1 table > tbody > tr');
console.log("COUNT: " + nodes.length);
var htmlEvents = [];
nodes.each(function() {
    var event = {};
    event.id = $(this).data('id').replace('comment-','');
    event.type = $(this).data('type');
    event.description = $(this).find('.game-details').text().trim()
    event.timestamp = $(this).find('.time-stamp').text().trim()
    htmlEvents.push(event);
})
console.log(htmlEvents);
</script>
