({
	init : function(component, event, helper) { 
	    component.set("v.Spinner", true);
	    var dbAction = component.get("c.getTemplates");
	    dbAction.setParams({
	        recordId : component.get("v.recordId")
	    });
        dbAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.templates", response.getReturnValue());
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(dbAction);   
	},
	
	preiewEmailTemplate : function(component, event, helper) {
	    var selectedTemplate = component.get("v.selectedTemplate");
	    if(selectedTemplate != undefined){
            component.set("v.isTemplateSelected", true);
              
            helper.getTemplateBody(component, event, helper);
            setTimeout(function(){
            var wrapper = document.getElementById("signature-pad");
                if(wrapper){
                        var canvas = wrapper.querySelector("canvas");
                        var signaturePad;
                    
                    // Adjust canvas coordinate space taking into account pixel ratio,
                    // to make it look crisp on mobile devices.
                    // This also causes canvas to be cleared.
                    function resizeCanvas() {
                        // When zoomed out to less than 100%, for some very strange reason,
                        // some browsers report devicePixelRatio as less than 1
                        // and only part of the canvas is cleared then.
                        var ratio =  Math.max(window.devicePixelRatio || 1, 1);
                        canvas.width = canvas.offsetWidth * ratio;
                        canvas.height = canvas.offsetHeight * ratio;
                        canvas.getContext("2d").scale(ratio, ratio);
                    }
                    
                    window.onresize = resizeCanvas;
                    resizeCanvas();
                    
                    window.signaturePad = new SignaturePad(canvas);  
                    
                    document.getElementById("btnClear").onclick=function(event){
                    event.preventDefault();
                    console.log(window.signaturePad);
                    window.signaturePad.clear();
                    }
                }
            },3000);
        }
	},
	
	closeModel : function(component, event, helper) {
	    // location.reload();
	   $A.get("e.force:closeQuickAction").fire();
	},  
    
    Acceptandclose : function(component, event, helper){
        component.set("v.Spinner", true);
        helper.getuploadSignature(component, event); 
	},
})