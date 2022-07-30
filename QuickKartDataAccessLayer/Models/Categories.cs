using System;
using System.Collections.Generic;

namespace QuickKartDataAccessLayer.Models
{
    public partial class Categories
    {
        public Categories()
        {
            Products = new HashSet<Products>();
        }

        public byte CategoryId { get; set; }
        public string CategoryName { get; set; }

        public ICollection<Products> Products { get; set; }
    }
}
