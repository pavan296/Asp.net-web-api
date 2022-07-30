using System;
using System.Collections.Generic;

namespace QuickKartDataAccessLayer.Models
{
    public partial class Roles
    {
        public Roles()
        {
            Users = new HashSet<Users>();
        }

        public byte RoleId { get; set; }
        public string RoleName { get; set; }

        public ICollection<Users> Users { get; set; }
    }
}
