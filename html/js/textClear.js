  $(document).on('propertychange keyup input paste', 'input.data_field', function(){
	  var io = $(this).val().length ? 1 : 0 ;
	  $(this).next('.icon_clear').stop().fadeTo(100,io);
  }).on('click', '.icon_clear', function() {
	  $(this).delay(100).fadeTo(100,0).prev('input').val('');
  });
  
  $('input.data_field').trigger('input');
