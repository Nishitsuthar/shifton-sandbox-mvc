({
	getTemplateBody : function(component, event, helper) {
        var recordId = component.get("v.recordId");
	    var action = component.get("c.getChangeOrderLines");
	    action.setParams({
	        recordId : recordId,
	        templateId : component.get("v.selectedTemplate")
	    });
	    action.setCallback(this, function(response){
	        var state = response.getState();
	        if(state === "SUCCESS"){
	            var result =  response.getReturnValue();
	            component.set("v.changeOrderLines", result);
	        }
	    });
	    $A.enqueueAction(action);
	},
	
	 getuploadSignature : function(component, event){
	    component.set("v.parentId",component.get("v.recordId")); 
        var recId= component.get("v.parentId");
        console.log('in helper');
         
        var signName = component.get("v.SignatureName");
        var signatureaction = component.get("c.savedFile");
        var toastEvent = $A.get('e.force:showToast');
        var vSplit = component.get("v.changeOrderLines");
        
        signatureaction.setParams({                                  
            recId : recId,
            templateId : component.get("v.selectedTemplate")
        });
        signatureaction.setCallback(this, function(e) {          
            if(e.getState()=='SUCCESS'){
                console.log('success');
                 var result =  e.getReturnValue();
                component.set("v.Spinner", false);
	           component.set("v.fileimageId", result); 
              var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": 'success',
                    "message": "File Saved Successfully"
                });
                toastEvent.fire();
               $A.get("e.force:closeQuickAction").fire();
	           // location.reload();
            }
            else{
                alert(JSON.stringify(e.getError()));
            }
        });
        $A.enqueueAction(signatureaction); 
        
    },
	
	
})