﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Rock.Web.Blocks.Cms
{
    public partial class Sites : Rock.Cms.CmsBlock
    {
        private string _action = string.Empty;
        private int _siteId = 0;

        protected void Page_Init( object sender, EventArgs e )
        {
            _action = PageParameter( "action" ).ToLower();
            switch ( _action )
            {
                case "":
                case "list":
                    DisplayList();
                    break;
                case "add":
                    _siteId = 0;
                    DisplayEdit( _siteId );
                    break;
                case "edit":
                    if ( Int32.TryParse( PageParameter( "SiteId" ), out _siteId ) )
                        DisplayEdit( _siteId );
                    else
                        throw new System.Exception( "Invalid Site Id" );
                    break;
            }
        }

        protected void Page_Load( object sender, EventArgs e )
        {
        }

        private void DisplayList()
        {
            phList.Visible = true;
            phDetails.Visible = false;

            Rock.Services.Cms.SiteService siteService = new Services.Cms.SiteService();
            gvList.DataSource = siteService.Queryable().ToList();
            gvList.DataBind();
        }

        private void DisplayEdit( int siteId )
        {
            phList.Visible = false;
            phDetails.Visible = true;

            using ( new Rock.Helpers.UnitOfWorkScope() )
            {
                Rock.Services.Cms.SiteService siteService = new Services.Cms.SiteService();
                Rock.Services.Cms.PageService pageService = new Services.Cms.PageService();
				Rock.Services.Cms.ThemeService themeService = new Services.Cms.ThemeService( Request.RequestContext.HttpContext.Server.MapPath( "~" ) );

                ddlDefaultPage.DataSource = pageService.Queryable().Where( p => p.ParentPage == null ).ToList();
                ddlDefaultPage.DataBind();

				ddlTheme.DataSource = themeService.GetThemesNames();
				ddlTheme.DataBind();

                if ( siteId > 0 )
                {
                    Rock.Models.Cms.Site site = siteService.GetSite( Convert.ToInt32( PageParameter( "SiteId" ) ) );
                    tbName.Text = site.Name;
                    tbDescription.Text = site.Description;
					//tbTheme.Text = site.Theme;
					ddlTheme.SelectedValue = site.Theme;
                    ddlDefaultPage.SelectedValue = site.DefaultPageId.ToString();
                }
                else
                {
                    tbName.Text = string.Empty;
                    tbDescription.Text = string.Empty;
                    //tbTheme.Text = string.Empty;
                }
            }
        }

        protected void lbSave_Click( object sender, EventArgs e )
        {
            using ( new Rock.Helpers.UnitOfWorkScope() )
            {
                Rock.Services.Cms.SiteService siteService = new Services.Cms.SiteService();
                Rock.Services.Cms.PageService pageService = new Services.Cms.PageService();

                Rock.Models.Cms.Site site = _action == "add" ?
                    new Rock.Models.Cms.Site() :
                    siteService.GetSite( _siteId );

                site.Name = tbName.Text;
                site.Description = tbDescription.Text;
				site.Theme = ddlTheme.SelectedValue;

                Rock.Models.Cms.Page page = pageService.GetPage( Convert.ToInt32( ddlDefaultPage.SelectedValue ) );
                site.DefaultPage = page;

                if ( _action == "add" )
                    siteService.AddSite( site );
                siteService.Save( site, CurrentPersonId );

                Response.Redirect( "~/site/list" );
            }
        }
    }
}