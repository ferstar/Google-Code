$(document).ready(function(){

    $('.confirm').click(function(e){
                e.preventDefault();
                var theHREF = $(this).attr("href");
        var elem = $(this).closest('.item');

        $.confirm({
            'title'     : 'Confirm Action',
            'message'   : 'Are you sure you want to do this?  It cannot be undone.',
            'buttons'   : {
                'Yes'   : {
                    'class' : 'red medium',
                    'action': function(){
                                                window.location.href = theHREF;
                    }
                },
                'No'    : {
                    'class' : 'green medium'
                }
            }
        });

    });

});

