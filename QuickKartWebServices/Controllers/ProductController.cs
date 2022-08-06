using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using QuickKartDataAccessLayer;
using QuickKartDataAccessLayer.Models;
using System;
using System.Collections.Generic;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace QuickKartWebServices.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductController : ControllerBase
    {
        private readonly QuickKartRepository _repository;
        private readonly IMapper _mapper;

        public ProductController(QuickKartRepository repository,IMapper mapper)
        {
            _repository = repository;
            _mapper = mapper;
        }


        // GET: api/<ProductController>
        [HttpGet]
        public JsonResult GetProducts()
        {
            List<Models.Product> products = new List<Models.Product>();
            try
            {
                List<Products> productList = _repository.GetProducts();
                if (productList != null)
                {
                    foreach(var product in productList)
                    {
                        Models.Product productObj=_mapper.Map<Models.Product>(product);
                        products.Add(productObj);
                    }
                }
            }
            catch (Exception ex)
            {
                products = null;
            }
            return new JsonResult(products);
        }

        // GET api/<ProductController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }

        // POST api/<ProductController>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<ProductController>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<ProductController>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
