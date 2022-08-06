using AutoMapper;
using QuickKartDataAccessLayer.Models;

namespace QuickKartWebServices
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Products, Models.Product>();
        }
        
    }
}
