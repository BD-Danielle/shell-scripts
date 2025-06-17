$(function(){
    var scalePage = function(){
        var scale = $(window).width() / 1050;
        if(scale > 1){
            scale = 1;
        }
        $('.PC #it708').css('transform', 'scale(' + scale + ')');
        
        if(scale < 1){
            $('.PC #it708-wrapper').css('height', parseInt($('#it708').css('height'), 10) * scale);
        }else{
            $('.PC #it708-wrapper').css('height', 'auto');
        }
    };

    if($(window).width() < 1050){
        scalePage();
    }
    
    window.onresize = function(event){
        scalePage();
    };
});
