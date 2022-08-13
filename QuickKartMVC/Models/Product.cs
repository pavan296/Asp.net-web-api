using System;

namespace QuickKartMVC.Models
{
    public class Product
    {
        public string ProductId { get; set; }
        public string ProductName { get; set; }
        public string CategoryId { get; set; }
        public decimal Price { get; set; }
        public int QuantityAvailable { get; set; }
    }

}
