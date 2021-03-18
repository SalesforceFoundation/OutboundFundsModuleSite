// Because a role is required for any user that owns a portal user account record
// we need to assign a role to the default admin (custom role due to a known scratch org bug).
final String roleDeveloperName = 'FundMaker';
final List<Schema.UserRole> roles = [
    SELECT Id
    FROM UserRole
    WHERE DeveloperName = :roleDeveloperName
    LIMIT 1
];
if (roles.isEmpty()) {
    // Create GrantMaker role
    final Schema.UserRole userRole = new Schema.UserRole(
        DeveloperName = roleDeveloperName,
        Name = roleDeveloperName
    );
    roles.add(userRole);
    insert userRole;
}

// Update the default scratch org user/adminUser to be "Aileen".
update new Schema.User(
    Id = UserInfo.getUserId(),
    UserRoleId = roles[0].Id,
    FirstName = 'Aileen',
    LastName = 'Davis',
    Alias = 'aileen',
    CommunityNickname = 'Aileen Davis',
    Title = 'Executive Director',
    Street = '1207 Clearwater Drive',
    City = 'Denver',
    State = 'CO',
    PostalCode = '80202',
    CompanyName = 'Grantwood Conservation Center'
    // TimeZoneSidKey defaults from CumulusCI settings.
);
