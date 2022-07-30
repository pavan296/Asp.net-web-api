using System;
using System.Collections.Generic;

namespace QuickKartDataAccessLayer.Models
{
    public partial class Users
    {
        public Users()
        {
            PurchaseDetails = new HashSet<PurchaseDetails>();
        }

        public string EmailId { get; set; }
        public string UserPassword { get; set; }
        public byte? RoleId { get; set; }
        public string Gender { get; set; }
        public DateTime DateOfBirth { get; set; }
        public string Address { get; set; }

        public Roles Role { get; set; }
        public ICollection<PurchaseDetails> PurchaseDetails { get; set; }
    }
}
