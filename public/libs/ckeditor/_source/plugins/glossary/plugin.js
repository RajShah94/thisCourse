﻿

CKEDITOR.plugins.add( 'glossary',
{
	init : function( editor )
	{
        editor.addCommand('glossary', {
        	
        	exec: function (editor)
        	{
        		alert('Hello!')
        		var style = new CKEDITOR.style( { element : 'a', attributes : {'href':'/glossary/item','rel':'tooltip','title':'Hell Yeah!'} } );
				style.type = CKEDITOR.STYLE_INLINE;
				style.apply( editor.document );
        	}
        });
        editor.ui.addButton('Glossary',
            {
                label: 'Glossary Item',
                command: 'glossary'
            });
    }
});