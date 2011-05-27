﻿using System;
using System.Collections.Generic;
using System.Web.Security;
using Rock.Cms;
using Rock.Repository.Cms;

using Facebook;
using System.Web;

namespace RockWeb.Blocks.Cms
{
    public partial class Login : CmsBlock
    {
        protected void Page_Init(object sender, EventArgs e)
        {
            
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Check for Facebook query string params. If exists, assume it's a redirect back from Facebook.
            if ( Request.QueryString["code"] != null )
            {
                ProcessOAuth( Request.QueryString["code"], Request.QueryString["state"] );
            }
        }

        /// <summary>
        /// Redirects to Facebook w/ necessary permissions required to gain user approval.
        /// </summary>
        /// <param name="sender">Trigger object of event</param>
        /// <param name="e">Arguments passed in</param>
        protected void ibFacebookLogin_Click( object sender, EventArgs e )
        {
            var returnUrl = Request.QueryString["returnurl"];
            var oAuthClient = new FacebookOAuthClient( FacebookApplication.Current ) { RedirectUri = new Uri( GetOAuthRedirectUrl() ) };
            oAuthClient.AppId = "201981526511937";
            oAuthClient.AppSecret = "79893a57ac39dbae0b05a8972319073b";

            // Grab publically available information. No special permissions needed for authentication.
            var loginUri = oAuthClient.GetLoginUrl( new Dictionary<string, object> { { "state", returnUrl } } );
            Response.Redirect( loginUri.AbsoluteUri );
        }

        /// <summary>
        /// Awaits permission of facebook user and will issue authenication cookie if successful.
        /// </summary>
        /// <param name="code">Facebook authorization code</param>
        /// <param name="state">Redirect url</param>
        private void ProcessOAuth( string code, string state )
        {
            FacebookOAuthResult oAuthResult;

            if ( FacebookOAuthResult.TryParse( Request.Url, out oAuthResult ) && oAuthResult.IsSuccess )
            {               
                var oAuthClient = new FacebookOAuthClient( FacebookApplication.Current ) { RedirectUri = new Uri( GetOAuthRedirectUrl() ) };
                oAuthClient.AppId = "201981526511937";
                oAuthClient.AppSecret = "79893a57ac39dbae0b05a8972319073b";
                dynamic tokenResult = oAuthClient.ExchangeCodeForAccessToken( code );
                string accessToken = tokenResult.access_token;

                FacebookClient fbClient = new FacebookClient( accessToken );
                dynamic me = fbClient.Get( "me" );
                var userRepository = new EntityUserRepository();
                string facebookId = me.id.ToString();
                var user = userRepository.FirstOrDefault( u => u.Username == facebookId && u.AuthenticationType == 2 );

                if ( user == null )
                {
                    // TODO: Show label indicating inability to find user corresponding to facebook id
                    return;
                }
                 
                FormsAuthentication.SetAuthCookie( user.Username, false );

                if ( state != null )
                {
                    Response.Redirect( state );
                } 
            }

            // TODO: Supply user feedback indicating authentication was not successful.
        }

        private string GetOAuthRedirectUrl()
        {
            // TODO: Does this actually provide the correct absolute path to the current page?
            //return new Uri( string.Format( "~/page/{0}/{1}", PageInstance.Id, Request.QueryString ) ).AbsoluteUri;
            //return HttpContext.Current.Request.Url.ToString();
            return "http://localhost:64987/RockWeb/login";
        }


    }
}