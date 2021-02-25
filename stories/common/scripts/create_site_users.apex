// param1 is a comma-delimited list of Contact.Email to create site users.
final List<String> emails = '%%%PARAM_1%%%'.split(',');

final Id fundseekerPlusLoginProfileId = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Fundseeker Plus Login'
    LIMIT 1
][0]
.Id;

final List<Schema.User> users = new List<Schema.User>();

for (Schema.Contact contact : [
    SELECT
        Id,
        FirstName,
        LastName,
        Email,
        Title,
        Phone,
        Fax,
        MobilePhone,
        MailingStreet,
        MailingCity,
        MailingState,
        MailingPostalCode,
        MailingCountry,
        Account.Name
    FROM Contact
    WHERE Email IN :emails AND Id NOT IN (SELECT ContactId FROM User)
    ORDER BY Title
]) {
    final String userAlias = contact.FirstName.toLowerCase().left(8);
    final String userEmail = UserInfo.getUserEmail().replace('@', '+' + userAlias + '@');
    users.add(
        new Schema.User(
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Email = userEmail,
            Username = contact.Email,
            Alias = userAlias,
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = fundseekerPlusLoginProfileId,
            ContactId = contact.Id,
            CommunityNickname = contact.FirstName,
            CompanyName = contact.Account.Name,
            Title = contact.Title,
            Phone = contact.Phone,
            Fax = contact.Fax,
            MobilePhone = contact.MobilePhone,
            Street = contact.MailingStreet,
            City = contact.MailingCity,
            State = contact.MailingState,
            PostalCode = contact.MailingPostalCode,
            Country = contact.MailingCountry
        )
    );
}
insert users;
