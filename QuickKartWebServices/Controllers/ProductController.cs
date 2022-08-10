using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using QuickKartDataAccessLayer;
using QuickKartDataAccessLayer.Models;
using System;
using System.Collections.Generic;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace QuickKartWebServices.Controllers
{
    [Route("api/[controller]/[action]")]
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
        [HttpGet]
        public JsonResult GetProduct(string productId)
        {
            Models.Product product = null;
            try
            {
                product=_mapper.Map<Models.Product>(_repository.GetProductDetails(productId));

            }
            catch(Exception ex)
            {
                product = null;
            }
            return new JsonResult(product);
        }

        // POST api/<ProductController>
        [HttpPost]
        public JsonResult AddProduct(Models.Product product)
        {
            bool status = false;
            try
            {
                status = _repository.AddProduct(_mapper.Map<Products>(product));
            }
            catch (Exception ex)
            {
                status = false;
            }
            return new JsonResult(status);
        }


        // PUT api/<ProductController>/5
        [HttpPut]
        public JsonResult UpdateProduct(Models.Product product)
        {
            bool status = false;
            try
            {
                status = _repository.UpdateProduct(_mapper.Map<Products>(product));
            }
            catch (Exception ex)
            {
                status = false;
            }
            return new JsonResult(status);
        }


        // DELETE api/<ProductController>/5
        [HttpDelete]
        public JsonResult DeleteProduct(string productId)
        {
            bool status = false;
            try
            {
                status = _repository.DeleteProduct(productId);
            }
            catch (Exception ex)
            {
                status = false;
            }
            return new JsonResult(status);
        }

    }
}
