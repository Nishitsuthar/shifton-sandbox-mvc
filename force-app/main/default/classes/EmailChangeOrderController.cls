public with sharing class EmailChangeOrderController {
    public EmailChangeOrderController() {

    }

    @AuraEnabled
    public Static String SendEmail(List<String> to, List<String> cc, List<String> files, String subject, String body, List<String> recordId, String templateId, String pdfFileName,List<String> emailIds,List<String> Ids){

            system.debug('To : '+to);
             system.debug('cc : '+cc);
             system.debug('files : '+files);
             system.debug('subject : '+subject);
             system.debug('body : '+body);
             system.debug('recordId : '+recordId);
             system.debug('templateId : '+templateId);
             system.debug('pdfFileName : '+pdfFileName);
             system.debug('emailIds : '+emailIds);
             system.debug('Ids : '+Ids);
            system.debug('Ids : '+Ids[0]);
            List<string> strTO = new List<string>();
            List<string> strCC = new List<string>();
            SET<Id> contactIdSet = new SET<Id>();
            List<Contact> conList;
            if (Schema.sObjectType.Contact.fields.Id.isAccessible() && Schema.sObjectType.Contact.fields.email.isAccessible()){
                conList = [Select Id, email
                           from Contact
                           where Id IN :to and email != null];
            }
            
            for (Contact con : conList){
                strTO.add(con.email);
                contactIdSet.add(con.Id);
            }
            List<Contact> ccConList;
            if (Schema.sObjectType.Contact.fields.Id.isAccessible() && Schema.sObjectType.Contact.fields.email.isAccessible()){
                ccConList = [Select Id, email
                             from Contact
                             where Id IN :cc and email != null];
            }
            for (Contact con : ccConList){
                strCC.add(con.email);
            }
            strTO.addAll(emailIds);
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(strTO);
            //mail.setTemplateId(templateId);
            system.debug('strCC --------> ' + strCC);
            if (strCC != null && strCC.size() > 0){
                mail.setCcAddresses(strCC);
            }
            
            EmailServicesAddress eServices;
            
            
            eServices = [SELECT Id, AuthorizedSenders, EmailDomainName, IsActive, LocalPart
                         FROM EmailServicesAddress
                         where LocalPart = 'projects'];
            
            string fromAddress = eServices.LocalPart + '@' + eServices.EmailDomainName;
            mail.setReplyTo(fromAddress);
            String emailsubject = '';
            String Name = '';
            
            mail.setTemplateId(templateId);
            
            list<buildertek__Admin_Interface_Node_Configuration__c> adminInterfaceNodeConfigurations = [Select Id, buildertek__Quote_Configuration__c, buildertek__Email_Subject__c, Name
                                                                                                        from buildertek__Admin_Interface_Node_Configuration__c
                                                                                                        WHERE Name = :'Change Order Configuration' and buildertek__Email_Subject__c != null
                                                                                                        limit 1];
            
            if (adminInterfaceNodeConfigurations.size() > 0){
                emailsubject = adminInterfaceNodeConfigurations[0].buildertek__Email_Subject__c;
                subject = subject + ' - '+ emailsubject + ' - [ref:' + 'recordId' + ']';
            } else{
                subject = subject + ' Change Order - [ref:' + 'recordId' + ']';
            }
            List<buildertek__ConfirmationPageSiteURL__c> confirmationurl = buildertek__ConfirmationPageSiteURL__c.getall().values();
            string SiteUrl;
            if (confirmationurl.size() > 0){
                SiteUrl = confirmationurl[0].buildertek__SiteURL__c;
            }
            body = body;
            system.debug('recordId-->'+recordId);
            system.debug('templateId-->'+templateId);
            system.debug('body-->'+body);
            
            mail.setSubject(subject);
            if (body != null && String.isNotBlank(body) && body != ''){
                mail.setHtmlBody(body);
            }else{
                
                mail.setHtmlBody('<p></p>');
            }
            
            if (conList.size() > 0){
                mail.setTargetObjectId(conList[0].Id);
                mail.setSaveAsActivity(true);
            }
            
            List<buildertek__RFQ_To_Vendor__c> rfqVendorList;
            rfqVendorList = [select Id, Name
                             from buildertek__RFQ_To_Vendor__c
                             where buildertek__RFQ__c in :recordId];
            
            
            // Attached record pdf as an attachment
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                if (String.isNotBlank(templateId)){
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(pdfFileName + '.pdf');
                  System.debug('Processs Begin');
                    efa.setBody(setAttachmentBody(recordId, templateId));
                   fileAttachments.add(efa);
                }
            System.debug('File attachement by Id : '+fileAttachments);
            List<ContentVersion> docList;
            list<Id> contentVersionIds = new list<Id>();
            
            docList = [Select Id, ContentDocumentId, Title, VersionData
                       from ContentVersion
                       where Id IN :files]; //where ContentDocumentId IN :files];
            
            
            system.debug('docList -----------> ' + docList);
            system.debug('docList size -------> ' + docList.size());
            if (docList.size() > 0){
                for (ContentVersion docs : docList){
                    Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
                    efa1.setFileName(docs.Title);
                    efa1.setBody(docs.VersionData);
                    fileAttachments.add(efa1);
                    //fileAttachments.add(docs);
                    contentVersionIds.add(docs.Id);
                }
            } 
            List<Attachment> attList;
            
            
            attList = [Select Id, Name, Body
                       from Attachment
                       where Id IN :files];
            
            system.debug([Select Id, Name, Body  from Attachment  where Id IN :files]);
            system.debug('attList -----------> ' + attList);
            system.debug('attList size -------> ' + attList.size());
            system.debug(docList.size() > 0);

            if (docList.size() > 0){
                for (Attachment att : attList){
                    system.debug(attList);

                    Messaging.Emailfileattachment efa2 = new Messaging.Emailfileattachment();
                    efa2.setFileName(att.Name);
                    efa2.setBody(att.Body);
                    fileAttachments.add(efa2);
                }
            }
            
            system.debug('fileAttachments ----->' + fileAttachments);
            system.debug('contentVersionIds ----->' + contentVersionIds);
            mail.setEntityAttachments(contentVersionIds);

                mail.setFileAttachments(fileAttachments);
            System.debug('Mail attachements : '+   mail);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            system.debug('results ----------> ' + results);
            if (results.size() > 0){
                if (results[0].isSuccess()){
                    string Toaddresses = '';
                    string CCaddresses = '';
                    integer i = 0;
                    for (String Str : strTO){
                        Toaddresses += Str;
                        if (strTO.size() > i){
                            Toaddresses += ';';
                        }
                        i++;
                    }
                    for (String Str : strCC){
                        CCaddresses += Str;
                        if (strCC.size() > i){
                            CCaddresses += ';';
                        }
                        i++;
                        
                    }
                    system.debug('CCaddresses ----------> ' + CCaddresses);
                    
                    
                    EmailMessage caseEmailMessage = new EmailMessage();
                    caseEmailMessage.fromAddress = UserInfo.getUserEmail();
                    system.debug('caseEmailMessage.fromAddress'+caseEmailMessage.fromAddress);
                    caseEmailMessage.ToAddress = Toaddresses;
                    system.debug('caseEmailMessage.ToAddress'+caseEmailMessage.ToAddress);
                    caseEmailMessage.FromName = UserInfo.getUserName();
                    system.debug('caseEmailMessage.ToAddress'+caseEmailMessage.FromName);
                    caseEmailMessage.CcAddress = CCaddresses;
                    system.debug('CCaddresses'+caseEmailMessage.CcAddress);
                    caseEmailMessage.Subject = subject;
                    system.debug('CCaddresses'+caseEmailMessage.Subject);
                    caseEmailMessage.HtmlBody = body;
                    system.debug('CCaddresses'+caseEmailMessage.HtmlBody);
                    caseEmailMessage.Incoming = False;
                    system.debug('CCaddresses'+caseEmailMessage.Incoming);
                    caseEmailMessage.buildertek__Is_Incoming_Email__c = false;
                    system.debug('CCaddresses'+caseEmailMessage.buildertek__Is_Incoming_Email__c);
                    caseEmailMessage.MessageDate = system.now();
                    system.debug('CCaddresses'+caseEmailMessage.MessageDate);
                    
                    system.debug('caseEmailMessage.TextBody ---------> ' + caseEmailMessage.TextBody);
                    system.debug('Content length ---------> ' + body.length());

                    caseEmailMessage.status = '5';
                    system.debug('status'+caseEmailMessage.status);
                    caseEmailMessage.buildertek__Subject__c = 'Re: ' + subject;
                    system.debug('status'+caseEmailMessage.buildertek__Subject__c);
                    
                    insert caseEmailMessage;
                    
                    System.debug('===========INSERT===============');
                    
                    EmailMessageRelation emr = new EmailMessageRelation();
                    emr.emailMessageId = caseEmailMessage.id;
                    emr.relationId = UserInfo.getUserId(); // user id / contact Id of the sender
                    emr.relationType = 'FromAddress';
                    emr.relationAddress = caseEmailMessage.fromAddress;
                    
                    insert emr;
                    
                    system.debug('*****************6^^^^^^**********************');
                    system.debug(caseEmailMessage.Id);
                    system.debug(files);
                    List<ContentVersion> attachmentList = [Select id,VersionData from ContentVersion where id IN:files];
                    
                    system.debug(attachmentList);
                    List<Attachment> newAttList = new List<Attachment>();
                    for (ContentVersion att : attachmentList){
                        Attachment attch = new Attachment();
                        attch.Body = att.VersionData;
                        attch.Name = 'test';
                        attch.ParentId = caseEmailMessage.Id; 
                        newAttList.add(attch);
                    }
                    system.debug(newAttList);
                    insert(newAttList);
                    system.debug(newAttList);
                }
                system.debug(body);
            }
            
            String message = 'Success';
            return message;
    }

    private static Blob  setAttachmentBody(List<String> recordId, String templateId){
        String str = '';
        List<Blob> a = new List<Blob>();
        System.debug('record id --> '+recordId);
        System.debug('templateID --> '+templateId);
     //   for(String recId : recordId){
            Pagereference pdf;
            pdf = Page.COPDF;
            pdf.getParameters().put('id',JSON.serialize(recordId));
            pdf.getParameters().put('DocTemplateId', templateId);
            pdf.setRedirect(true);
            System.debug('pdf log --> '+pdf.getContent());
            Blob blobbody = !Test.isRunningTest() ? pdf.getContent() : Blob.ValueOf('dummy text');
    /*        a.add(blobbody);
        } */
      /*  for(Blob b : a){
            Blob d = Blob.valueOf(EncodingUtil.base64Encode(b));
            str += EncodingUtil.convertToHex(d);
        }     */
      //  str = EncodingUtil.convertToHex(Blob.valueOf(a[0].toString())) +  EncodingUtil.convertToHex(Blob.valueOf(a[1].toString()));
     /*   str = EncodingUtil.convertToHex(a[0]) + EncodingUtil.convertToHex(a[1]);
        Blob c = EncodingUtil.convertFromHex(str); */
        return blobbody;
    }
}