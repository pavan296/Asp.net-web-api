using System;

namespace QuickKartWebServices.Models
{
    public class Product
    {
        public string ProductId { get; set; }
        public string ProductName { get; set; }
        public Nullable<byte> CategoryId { get; set; }
        public decimal Price { get; set; }
        public int QualityAvailable { get; set; }
    }
}
