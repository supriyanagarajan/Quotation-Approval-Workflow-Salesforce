trigger QuotationApprovalTrigger on Quotation__c (after update) {

    Set<Id> contactIds = new Set<Id>();

    for (Quotation__c q : Trigger.new) {
        if (q.Contact__c != null) {
            contactIds.add(q.Contact__c);
        }
    }

    Map<Id, Contact> contactMap = new Map<Id, Contact>(
        [SELECT Id, Name, Email FROM Contact WHERE Id IN :contactIds]
    );

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (Quotation__c q : Trigger.new) {

        Quotation__c oldQ = Trigger.oldMap.get(q.Id);

        if (q.Contact__c == null || !contactMap.containsKey(q.Contact__c)) {
            continue;
        }

        Contact con = contactMap.get(q.Contact__c);

        if (String.isBlank(con.Email)) {
            continue;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[]{con.Email});

        // Draft
        if (q.Approval_Status__c == 'Draft' &&
            oldQ.Approval_Status__c != 'Draft') {

            mail.setSubject('Quotation Saved as Draft');

            mail.setPlainTextBody(
                'Dear ' + con.Name + ',\n\n' +
                'Your quotation "' + q.Name + '" has been saved as Draft.\n\n' +
                'Status : Draft\n\n' +
                'Regards,\n' +
                'Quotation Approval Team\n' +
                'ELGI Equipments Ltd.'
            );

            emails.add(mail);
        }

        // Pending
        else if (q.Approval_Status__c == 'Pending' &&
                 oldQ.Approval_Status__c != 'Pending') {

            mail.setSubject('Quotation Submitted for Approval');

            mail.setPlainTextBody(
                'Dear ' + con.Name + ',\n\n' +
                'Your quotation "' + q.Name + '" has been submitted for approval.\n\n' +
                'Status : Pending\n\n' +
                'You will receive another email once the quotation is approved or rejected.\n\n' +
                'Regards,\n' +
                'Quotation Approval Team\n' +
                'ELGI Equipments Ltd.'
            );

            emails.add(mail);
        }

        // Approved
        else if (q.Approval_Status__c == 'Approved' &&
                 oldQ.Approval_Status__c != 'Approved') {

            mail.setSubject('Quotation Approved Successfully');

            mail.setPlainTextBody(
                'Dear ' + con.Name + ',\n\n' +
                'Congratulations!\n\n' +
                'Your quotation "' + q.Name + '" has been approved successfully.\n\n' +
                'Status : Approved\n\n' +
                'Thank you for choosing ELGI Equipments Ltd.\n\n' +
                'Regards,\n' +
                'Quotation Approval Team\n' +
                'ELGI Equipments Ltd.'
            );

            emails.add(mail);
        }

        // Rejected
        else if (q.Approval_Status__c == 'Rejected' &&
                 oldQ.Approval_Status__c != 'Rejected') {

            mail.setSubject('Quotation Rejected');

            mail.setPlainTextBody(
                'Dear ' + con.Name + ',\n\n' +
                'We regret to inform you that your quotation "' + q.Name + '" has been rejected.\n\n' +
                'Status : Rejected\n\n' +
                'Please contact our sales team for more information.\n\n' +
                'Regards,\n' +
                'Quotation Approval Team\n' +
                'ELGI Equipments Ltd.'
            );

            emails.add(mail);
        }
    }

    if (!emails.isEmpty()) {
        Messaging.sendEmail(emails);
    }
}