public class AnnouncementTriggerHandler {

    public static void sendAnnouncementEmails(List<Announcement__c> announcementList) {
        Set<String> setOfAdminEmails = new Set<String>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Admin__c adn : [SELECT Id, Name, Email__c FROM Admin__c]) {
            if(adn.Email__c != null) {
                setOfAdminEmails.add(adn.Email__c);
            }
        }
        System.debug('setOfAdminEmails :::: '+setOfAdminEmails);
        for (Announcement__c announce : announcementList) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();            
            DateTime startDateTim = DateTime.newInstance(announce.Start_Date_Time__c.year(), announce.Start_Date_Time__c.month(), announce.Start_Date_Time__c.day());
            String formattedDateForStart = startDateTim.format('dd-MMM-yy');
            DateTime endDateTim = DateTime.newInstance(announce.End_Date_Time__c.year(), announce.End_Date_Time__c.month(), announce.End_Date_Time__c.day());
            String formattedDateForEnd = endDateTim.format('dd-MMM-yy');
            String emailBody = 'Hi Sir, <br><br>';
            String siteLink = 'https://bemee--edu360sbx.sandbox.my.site.com/s/';
            emailBody += announce.Name + ' has applied for Announcement.<br> Please log on to ' +siteLink+' and review the Announcement application.<br>'
                + 'Following are the applied Announcement details:<br><br>'
                + '<b>Annoucement type:</b> ' + announce.Type__c + '<br>'
                + '<b>Start Date:</b> ' + formattedDateForStart + '<br>'
                + '<b>End Date:</b> ' + formattedDateForEnd + '<br>'
                + '<b>Number of days:</b> ' + announce.Announcement_Days__c + '<br>'
                + '<b>Description:</b><br>'+announce.Description__c + '<br>'
                + siteLink
                + ' to approve/reject this request.';
            emailBody += '<br><br>Regards,<br>Gurukul Vyavasthapan';
            emailBody += '<br> ' + 'This e-mail is generated from ' +siteLink;
            if (!setOfAdminEmails.isEmpty()) {
                email.setToAddresses(new String[setOfAdminEmails]);
            }
            email.setSubject('Announcement Request');
            email.setHtmlBody(emailBody);
            System.debug('email ::: '+email);
            emailList.add(email);
        }
        
        System.debug('emailList ::: '+emailList);
        
        if (!emailList.isEmpty()) {
            Messaging.sendEmail(emailList);
        }
    }
    
    public static void handleAnnouncementChanges(List<Announcement__c> announcementList, Map<Id, Announcement__c> mapOfAnnouncement) {
        List<Announcement__c> approvedOrRejectedAnnouncement = new List<Announcement__c>();
        
        for (Announcement__c announce : announcementList) {
            Announcement__c oldAnnounce = mapOfAnnouncement.get(announce.Id);
            
            if ((announce.Status__c == 'Approved' || announce.Status__c == 'Rejected') &&
                (oldAnnounce.Status__c != 'Approved' && oldAnnounce.Status__c != 'Rejected')) {
                    approvedOrRejectedAnnouncement.add(announce);
                }
        }
        
        if (!approvedOrRejectedAnnouncement.isEmpty()) {
            sendAnnouncementApprovalEmails(approvedOrRejectedAnnouncement);
        }
    }
    
    private static void sendAnnouncementApprovalEmails(List<Announcement__c> announcements) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Set<Id> teacherIds = new Set<Id>();
        for (Announcement__c announce : announcements) {
            teacherIds.add(announce.Teacher__c);
        }
        
        Map<Id, Teacher__c> teacherMap = new Map<Id, Teacher__c>([SELECT Id, Email__c FROM Teacher__c WHERE Id IN :teacherIds]);
        
        for (Announcement__c announce : announcements) {
            Teacher__c teacher = teacherMap.get(announce.Teacher__c);
            
            if (teacher != null && teacher.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{teacher.Email__c});
                email.setSubject('Announcement '+ announce.Status__c +' Notification');
                email.setPlainTextBody('Your Announcement has been ' + announce.Status__c + '.');
                emails.add(email);
            }
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}