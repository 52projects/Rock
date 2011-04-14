﻿using System;
using System.Collections.Generic;
using System.Runtime.Caching;

namespace Rock.Cms.Cached
{
    /// <summary>
    /// Information about a block that is required by the rendering engine.
    /// This information will be cached by the engine
    /// </summary>
    public class Block
    {
        /// <summary>
        /// Use Static Read() method to instantiate a new Block object
        /// </summary>
        private Block() { }

        public int Id { get; private set; }
        public string Path { get; private set; }
        public string Name { get; private set; }
        public string Description { get; private set; }
        public Dictionary<string, string> AttributeValues { get; private set; }

        private List<int> AttributeIds = new List<int>();
        /// <summary>
        /// List of attributes associated with the block.  This object will not include values.
        /// To get values associated with the current block instance, use the AttributeValues
        /// </summary>
        public List<Rock.Cms.Cached.Attribute> Attributes
        {
            get
            {
                List<Rock.Cms.Cached.Attribute> attributes = new List<Rock.Cms.Cached.Attribute>();

                foreach ( int id in AttributeIds )
                    attributes.Add( Attribute.Read( id ) );

                return attributes;
            }
        }

        public void SaveAttributeValues(int? personId)
        {
            Rock.Services.Cms.BlockService blockService = new Services.Cms.BlockService();
            Rock.Models.Cms.Block blockModel = blockService.GetBlock( this.Id );

            if ( blockModel != null )
            {
                blockService.LoadAttributes( blockModel );
                foreach ( Rock.Models.Core.Attribute attribute in blockModel.Attributes )
                    blockService.SaveAttributeValue( blockModel, attribute, this.AttributeValues[attribute.Name], personId );
            }
        }

        #region Static Methods

        private static string CacheKey( int id )
        {
            return string.Format( "Rock:Block:{0}", id );
        }

        /// <summary>
        /// Returns Block object from cache.  If block does not already exist in cache, it
        /// will be read and added to cache
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public static Block Read( int id )
        {
            string cacheKey = Block.CacheKey( id );

            ObjectCache cache = MemoryCache.Default;
            Block block = cache[cacheKey] as Block;

            if ( block != null )
                return block;
            else
            {
                Rock.Services.Cms.BlockService blockService = new Services.Cms.BlockService();
                Rock.Models.Cms.Block blockModel = blockService.GetBlock( id );
                if ( blockModel != null )
                {
                    block = new Block();
                    block.Id = blockModel.Id;
                    block.Path = blockModel.Path;
                    block.Name = blockModel.Name;
                    block.Description = blockModel.Description;

                    blockService.LoadAttributes( blockModel );

                    block.AttributeValues = blockModel.AttributeValues;

                    foreach ( Rock.Models.Core.Attribute attribute in blockModel.Attributes )
                    {
                        block.AttributeIds.Add( attribute.Id );
                        Attribute.Read( attribute );
                    }

                    cache.Set( cacheKey, block, new CacheItemPolicy() );

                    return block;
                }
                else
                    return null;

            }
        }

        /// <summary>
        /// Removes block from cache
        /// </summary>
        /// <param name="guid"></param>
        public static void Flush( int id )
        {
            ObjectCache cache = MemoryCache.Default;
            cache.Remove( Block.CacheKey( id ) );
        }

        #endregion
    }
}